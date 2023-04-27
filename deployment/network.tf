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

resource "azurerm_virtual_network" "bootstrap" {
  name                = "vnet-bootstrap-${local.suffix}"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  tags                = var.tags
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "shared" {
  name                 = "subnet-bootstrap-shared-${local.suffix}"
  resource_group_name  = azurerm_resource_group.bootstrap.name
  virtual_network_name = azurerm_virtual_network.bootstrap.name
  address_prefixes     = [var.address_space]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_private_dns_zone" "created_zones" {
  for_each            = var.existing_dns_zones_rg == null ? local.private_dns_zones : {}
  name                = each.value
  resource_group_name = azurerm_resource_group.bootstrap.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "all" {
  for_each              = var.existing_dns_zones_rg == null ? azurerm_private_dns_zone.created_zones : data.azurerm_private_dns_zone.existing_zones
  name                  = "vnl-${each.value.name}-bootstrap-${local.suffix}"
  resource_group_name   = azurerm_resource_group.bootstrap.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.bootstrap.id
}

resource "azurerm_network_security_group" "bootstrap" {
  name                = "nsg-bootstrap-${local.suffix}"
  location            = azurerm_resource_group.bootstrap.location
  resource_group_name = azurerm_resource_group.bootstrap.name
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.bootstrap.id
}

resource "azurerm_network_watcher_flow_log" "bootstrap" {
  count                     = var.network_watcher_name != null ? 1 : 0
  name                      = "nw-log-bootstrap-${local.suffix}"
  resource_group_name       = var.network_watcher_resource_group_name
  network_watcher_name      = var.network_watcher_name
  network_security_group_id = azurerm_network_security_group.bootstrap.id
  storage_account_id        = azurerm_storage_account.bootstrap.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.bootstrap.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.bootstrap.location
    workspace_resource_id = azurerm_log_analytics_workspace.bootstrap.id
    interval_in_minutes   = 10
  }
}
