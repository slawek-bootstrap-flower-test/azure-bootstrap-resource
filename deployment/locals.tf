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

locals {
  suffix            = "${var.bootstrap_id}-${var.environment}"
  suffix_truncated  = substr(replace(replace(local.suffix, "-", ""), "_", ""), 0, 17)
  private_dns_zones = merge(local.required_private_dns_zones, var.create_private_dns_zones)

  # DNS Zones required by bootstrap (for private links)
  required_private_dns_zones = {
    blob = "privatelink.blob.core.windows.net"
  }
}
