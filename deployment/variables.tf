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

variable "bootstrap_id" {
  description = "Unique suffix to apply to resource names/ids"
  type        = string

  validation {
    condition     = length(var.bootstrap_id) <= 12
    error_message = "Must be 12 chars or less"
  }

  validation {
    condition     = can(regex("^[a-z0-9\\_-]*$", var.bootstrap_id))
    error_message = "Cannot contain spaces, uppercase or special characters except '-' and '_'"
  }
}

variable "location" {
  description = "The location to deploy resources"
  type        = string

  validation {
    condition     = can(regex("[a-z]+", var.location))
    error_message = "Only lowercase letters allowed"
  }
}

variable "environment" {
  description = "Environment name to differentiate deployments (ie. dev, prod)"
  type        = string

  validation {
    condition     = length(var.environment) <= 12
    error_message = "Must be 12 chars or less"
  }

  validation {
    condition     = can(regex("^[a-z0-9\\_-]*$", var.environment))
    error_message = "Cannot contain spaces, uppercase or special characters except '-' and '_'"
  }
}

variable "tags" {
  description = "Map of string to add as resource tags to all deployed resources"
  type        = map(string)
  default     = {}
}

variable "github_runner_token" {
  description = "Github persional access token with admin and runner scopes to be able to register GH runners"
  type        = string
}

variable "github_organization" {
  description = "GitHub organisation in which to register the build agent (runner)"
  type        = string
}

variable "github_runner_version" {
  description = "Release version of the GitHub runner to use"
  type        = string
  default     = "2.303.0"

  validation {
    condition     = !startswith(var.github_runner_version, "v")
    error_message = "Please remove the v prefix from the version number"
  }
}

variable "github_runner_instances" {
  description = "The number of GitHub runner instances to deploy"
  type        = number
  default     = 1
}

variable "address_space" {
  description = "Address space for vnet. This must not overlap with any addresses that will be peered. e.g. 10.0.0.0/24"
  type        = string
  default     = "10.0.0.0/24"
}

variable "network_watcher_name" {
  description = "Name of the network watcher resource in which to add the flow logs"
  type        = string
  default     = null
}

variable "network_watcher_resource_group_name" {
  description = "Resource group in which the network watcher exists"
  type        = string
  default     = null
}

variable "create_private_dns_zones" {
  description = <<EOF
The private DNS zones to create that are required by subsequent deployments that bootstrap
will be peered to. Will be ignored if existing_dns_zones_rg is set.
EOF
  type        = map(string)
  default     = {}
}

variable "existing_dns_zones_rg" {
  description = <<EOF
The resource group name containing existing private DNS zones to link to for private links. If
unspecified, bootstrap will create the zones it requires.
EOF
  type        = string
  default     = null
}
