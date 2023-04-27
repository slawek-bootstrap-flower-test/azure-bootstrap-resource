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

locals {
  environment = get_env("ENVIRONMENT", "dev")
  state_file  = "terraform.${local.environment}.tfstate"

  # Root config from config.yaml
  root_config = yamldecode(file("${get_repo_root()}/config.yaml"))

  # Environment-specific config for set environment with config.{ENVIRONMENT}.yaml format
  env_config_path = "${get_repo_root()}/config.${local.environment}.yaml"
  env_config      = fileexists(local.env_config_path) ? yamldecode(file(local.env_config_path)) : null
}

terraform {
  before_hook "add_ip_exceptions" {
    commands     = ["apply", "destroy"]
    execute      = ["${get_repo_root()}/scripts/modify_ip_exceptions.sh", "add", local.state_file]
  }

  extra_arguments "auto_approve" {
    commands  = ["apply"]
    arguments = ["-auto-approve"]
  }

  after_hook "remove_ip_exceptions" {
    commands     = ["apply", "destroy"]
    execute      = ["${get_repo_root()}/scripts/modify_ip_exceptions.sh", "remove", local.state_file]
    run_on_error = true
  }

  after_hook "clean_secrets_from_state" {
    commands     = ["apply"]
    execute      = ["${get_repo_root()}/scripts/clean_terraform_state.sh", local.state_file]
    run_on_error = true
  }
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "1.3.7"

  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "3.47.0"
    }
  }

  backend "local" {
    path = "${local.state_file}"
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

# Generate Terraform variables from config.yaml file & config.{environment}.yaml file (if present)
# For vars defined in both root and env config, env config will take precendence
inputs = merge(local.root_config, local.env_config, {
  environment = local.environment
}) 
