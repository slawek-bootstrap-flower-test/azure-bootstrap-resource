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

resource "azurerm_storage_account" "bootstrap" {
  name                              = "stgbtstr${local.suffix_truncated}"
  resource_group_name               = azurerm_resource_group.bootstrap.name
  location                          = azurerm_resource_group.bootstrap.location
  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = true  # Turned off post apply
  enable_https_traffic_only         = true
  tags                              = var.tags

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    # The deployers IP exception will be removed post apply, but must be present to create the container
    ip_rules                   = [chomp(data.http.local_ip.response_body)]
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.bootstrap.name
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-bootstrap-${local.suffix}"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  subnet_id           = azurerm_subnet.shared.id

  private_service_connection {
    name                           = "private-service-connection-blob-${local.suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.bootstrap.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-${local.suffix}"
    private_dns_zone_ids = [
      var.existing_dns_zones_rg == null
        ? azurerm_private_dns_zone.created_zones["blob"].id
        : data.azurerm_private_dns_zone.existing_zones["blob"].id
    ]
  }
}
