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
# limitations under the License.

SHELL:=/bin/bash
MAKEFILE_FULLPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE_FULLPATH))

target_title = @echo -e "\n\e[34m»»» 🥾\e[96m$(1)\e[0m...\n"

all: deploy

deploy:  ## Deploy all bootstrap resources
	$(call target_title, "Deploying Azure Bootstrap") \
	&& cd ${MAKEFILE_DIR}/deployment \
	&& terragrunt init -reconfigure \
	&& terragrunt apply \
	&& printf "\n 🥾 Use the below values for your GitHub configuration:\033[36m\n\n" \
	&& terraform output -json \
	  | jq -r 'with_entries(.value |= .value) | to_entries | map("\(.key | ascii_upcase)=\(.value | tostring)") |.[]'

destroy: ## Destroy all bootstrap resources
	$(call target_title, "Destroying Azure Bootstrap") \
	&& cd ${MAKEFILE_DIR}/deployment \
	&& terragrunt init -reconfigure \
	&& terragrunt destroy
