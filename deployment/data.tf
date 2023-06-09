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

data "http" "local_ip" {
  url = "https://api64.ipify.org"
}

# If an existing dns zones rg is set, read the required zones instead of creating them
data "azurerm_private_dns_zone" "existing_zones" {
  for_each            = var.existing_dns_zones_rg != null ? local.required_private_dns_zones : {}
  name                = each.value
  resource_group_name = var.existing_dns_zones_rg
}
