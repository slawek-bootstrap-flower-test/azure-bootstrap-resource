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

data "template_file" "cloud_config" {
  template = file("${path.module}/cloud-config.yaml")

  vars = {
    GITHUB_RUNNER_TOKEN   = var.github_runner_token
    GITHUB_ORGANIZATION   = var.github_organization
    GITHUB_RUNNER_VERSION = var.github_runner_version
    GITHUB_RUNNER_LABEL   = local.gh_runner_label
    USERNAME              = local.gh_runner_vm_username
  }
}

data "template_cloudinit_config" "build_agent" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_config.rendered
  }
}
