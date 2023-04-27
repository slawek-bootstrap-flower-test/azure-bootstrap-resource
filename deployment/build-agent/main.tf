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

resource "random_password" "gh_runner_vm" {
  length           = 32
  lower            = true
  min_lower        = 1
  upper            = true
  min_upper        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "_%@"
}

resource "azurerm_linux_virtual_machine_scale_set" "gh_runner" {
  name                  = "vm-gh-runner-${var.suffix}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  sku                   = "Standard_B2s"
  instances             = var.github_runner_instances

  admin_username = local.gh_runner_vm_username
  admin_password = random_password.gh_runner_vm.result

  disable_password_authentication = false

  custom_data = data.template_cloudinit_config.build_agent.rendered

  os_disk {
    disk_size_gb         = 128
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  network_interface {
    name    = "nic-gh-runner-vm-${var.suffix}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.shared_subnet_id
    }
  }

  boot_diagnostics {}

  extension {
    name                       = "AzureMonitorLinuxAgent"
    publisher                  = "Microsoft.Azure.Monitor"
    type                       = "AzureMonitorLinuxAgent"
    type_handler_version       = "1.25"
    automatic_upgrade_enabled  = true
    auto_upgrade_minor_version = true
  }
}

resource "azurerm_monitor_data_collection_rule" "gh_runner" {
  name                = "dcr-gh-runner-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "GH runner logs and metrics"

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "logs"
    }

    azure_monitor_metrics {
      name = "metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["metrics"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["logs"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      streams        = ["Microsoft-Syslog"]
      name           = "runner-syslog"
    }

    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["Processor(*)\\% Processor Time"]
      name                          = "runner-perfcounter"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "gh_runner" {
  name                    = "dcra-gh-runner-${var.suffix}"
  target_resource_id      = azurerm_linux_virtual_machine_scale_set.gh_runner.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.gh_runner.id
  description             = "GH runner scale set"
}
