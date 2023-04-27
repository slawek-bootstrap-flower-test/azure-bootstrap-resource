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

resource "azurerm_container_registry" "bootstrap" {
  name                = "acrbtstr${local.suffix_truncated}"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

resource "azurerm_container_registry_task" "purge_stale_images" {
  name                  = "purgeStaleImages"
  container_registry_id = azurerm_container_registry.bootstrap.id

  platform {
    os           = "Linux"
    architecture = "amd64" 
  }

  encoded_step {
    task_content = <<EOF
version: v1.1.0
steps: 
  - cmd: acr purge --untagged --ago 7d
    disableWorkingDirectoryOverride: true
    timeout: 3600
EOF
  }

  agent_setting {
    cpu = 2
  }

  timer_trigger {
    name     = "daily"
    schedule = "0 0 * * *"
    enabled  = true
  }
}
