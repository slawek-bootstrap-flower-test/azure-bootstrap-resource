#!/bin/bash
#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEPLOYER_IP_ADDRESS="$(curl -s 'https://api64.ipify.org')"
MODE="$1"
STATE_FILE="$2"

function storage_account_exists {
    cd "${SCRIPT_DIR}/../deployment"
    terraform state list | grep -q "azurerm_storage_account.bootstrap"
}

if [ ! -f "${SCRIPT_DIR}/../deployment/${STATE_FILE}" ]; then
    echo "No state file found - will not modify any IP exceptions"
    exit 0
fi

if storage_account_exists; then

    echo -n "Modifying to [$MODE] storage account IP exception..."
    STORAGE_ACCOUNT_NAME=$(terraform output ci_storage_account | tr -d '"')
    RESOURCE_GROUP_NAME=$(terraform output ci_resource_group | tr -d '"')

    if [ "$MODE" = "add" ]; then
        NETWORK_SWITCH="Enabled" 
    elif [ "$MODE" = "remove" ]; then
        NETWORK_SWITCH="Disabled"
    else
        echo "Unrecognised command"
        exit 1
    fi

    az storage account network-rule "${MODE}" --account-name "$STORAGE_ACCOUNT_NAME" \
    --ip-address "$DEPLOYER_IP_ADDRESS" > /dev/null

    az storage account update --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --public-network-access "$NETWORK_SWITCH" > /dev/null

    echo "done"
    sleep 10  # Azure CLI does not wait long enough
fi
