# 🥾 Azure-Bootstrap

Utility for bootstrapping common Azure resources needed to store Terraform state, containers and configure build agents.

## Prerequisites

This repo uses Terraform, Terragrunt and the Azure CLI. Ensure you're either running this repo from its [Devcontainer in VS Code](https://code.visualstudio.com/docs/devcontainers/containers) by selecting `Re-open in Container`, or that you have [Terraform](https://developer.hashicorp.com/terraform/downloads), [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) and the [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your local machine. 

## Getting started

1. Create a new private repository using this template repo, then clone and check it out.

2. If you wish to check in your state and config (we recommend you do so it's not just saved on your local machine), remove this from the `.gitignore` file:

    ```
    # Exclude the top level config file
    config.yaml
    # Exclude the terraform state in the public template repo
    *.tfstate
    *.tfstate*
    ```

3. Copy the `config.sample.yaml` to `config.yaml` and configure the appropriate settings:

    ```bash
    cp config.sample.yaml config.yaml
    ```

    > See [`deployment/variables.tf`](deployment/variables.tf) for the descriptions of each setting.

4. Log into Azure and optionally set a different subscription from your default:

    ```bash
    az login
    az account set -s <YOUR_SUBSCRIPTION_ID>
    ```

5. Create a fine-grained Github Organization PAT for registering runners, with the **Resource Owner** set to the Organization you want the runners to be shared within. This PAT must have **Organization Administration: Read and write** and **Self-hosted Runners: Read and write** scopes (as per the [docs](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-an-organization)).

    Copy the value; you will be prompted for this by Terraform when running `make` (or you can export it as an environment variable called `TF_VAR_github_runner_token`).

    > Note: be conscious of the expiry time that you set. You can generate a new PAT at any time and have shorter expiries for security, but ensure that you re-deploy with the new PAT before the old one expires, otherwise your build agents could stop functioning.

6. Deploy the bootstrap resources:

    ```bash
    make deploy ENVIRONMENT=dev
    ```

    Set `ENVIRONMENT` to an environment name to deploy (i.e. `dev`, `prod`). When prompted, enter your GitHub PAT token (if you didn't export it as an env var).

7. After successfully deploying, the values you'll need to use the bootstrap environment for your CI deployments are printed to the console. Make sure you capture these and use for the next section.


## Using for CI

Using the values outputted from the deployment, you can now configure your other repositories' GitHub actions to use the bootstrap resources.

### Virtual Network Peering

The first thing you need to do in a deployment of resources you wish to be accessible by the bootstrap runners (and anything running in them from your actions, like Terraform) is to [peer](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview) that deployment's virtual network with the bootstrap vnet.

You can do this using the outputted `CI_PEERING_VNET` and `CI_RESOURCE_GROUP` values, which is the bootstrap's vnet name and resource group name. In Terraform, it would look something like this:

```hcl
data "azurerm_virtual_network" "bootstrap" {
    name                = var.ci_vnet_name # Populated from CI_PEERING_VNET
    resource_group_name = var.ci_rg_name # Populated from CI_RESOURCE_GROUP
}

resource "azurerm_virtual_network_peering" "bootstrap_to_flowehr" {
    name                      = "peer-bootstrap-to-flwr"
    resource_group_name       = azurerm_resource_group.flwr.name
    virtual_network_name      = var.ci_vnet_name
    remote_virtual_network_id = azurerm_virtual_network.flwr.name
}

resource "azurerm_virtual_network_peering" "flowehr_to_bootstrap" {
    name                      = "peer-flwr-to-bootstrap"
    resource_group_name       = azurerm_resource_group.flwr.name
    virtual_network_name      = azurerm_virtual_network.flwr.name
    remote_virtual_network_id = data.azurerm_virtual_network.bootstrap.id
}
```

### GitHub Runners

1. Navigate to your GitHub Organization's settings, then Actions, then create a new organization-scoped variable called `CI_GITHUB_RUNNER_LABEL` and paste the corresponding value from the bootstrap output.

> You can do this as a repository-scoped variable instead if you prefer, but will need to make sure you've defined it in every repository in which you wish to populate the runner's label.

2. Configure your relevant GitHub Workflow files to use this (`${{ vars.CI_GITHUB_RUNNER_LABEL }}`) in any relevant job's `runs-on` parameter.

If you're using these runners on a public repository, you'll also need to go to your Organization settings, and within *Actions/Runners/Runner Groups*, pick the group containing your runners (typically **Default**), then tick the box that says **Allow public repositories**.

### Storage & Azure Container Registry

A key use-case for having storage and a container registry in a central CI/boostrap environment is for managing [Terraform state](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) and [Dev containers](https://containers.dev).

For an example of how this is used, see the [UCLH-Foundry/FlowEHR repo](https://github.com/UCLH-Foundry/FlowEHR). The `CI_CONTAINER_REGISTRY` and `CI_STORAGE_ACCOUNT` values are passed in via a GitHub environment and used by the workflows to store dev containers Terraform state for the FlowEHR infrastructure deployments.


## Security considerations

We recommend peering the Bootstrap VNet with a hub network in your organization containing a Network Virtual Appliance (firewall), and configuring your private fork of this repo to implement [User Defined Routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview) to direct all traffic to that firewall.

As part of this, ensure that you have whitelisted the appropriate domains that the GitHub runners required to function. See [here](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#communication-requirements) for details.


## Troubleshooting

### GitHub Runner not registering

If you've deployed and can't see a runner registration in your Organization's settings (under the Actions/Runners section), it might have failed registration. You can investigate this by finding the Virtual Machine Scale Set within the bootstrap resource group you've deployed, clicking **Instances**, clicking the first VM in the list (if you have multiple), then selecting **Boot Diagnostics**.

In the **Serial Log** tab you'll see the boot log. Near the bottom in the `cloud-init` output you should see `Registering GH runner..`. Below that will be any output related to the API call to GitHub to try and register the runner. If it's a 403, you've likely not given the right scopes to your PAT. Create a new one and ensure it has the right permissions (see Getting Started), export it as an env var and then re-run bootstrap deployment.

If you see some connectivity issues, it's likely that outbound traffic is being blocked to GitHub. Ensure if you have NSGs or a firewall in place that the [appropriate domains and IPs](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#communication-requirements) are whitelisted.
