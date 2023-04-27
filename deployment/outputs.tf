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

output "ci_resource_group" {
  value = azurerm_resource_group.bootstrap.name
}

output "ci_container_registry" {
  value = azurerm_container_registry.bootstrap.name
}

output "ci_storage_account" {
  value = azurerm_storage_account.bootstrap.name
}

output "ci_peering_vnet" {
  value = azurerm_virtual_network.bootstrap.name
}

output "ci_github_runner_label" {
  value = module.build_agent.github_runner_label
}
