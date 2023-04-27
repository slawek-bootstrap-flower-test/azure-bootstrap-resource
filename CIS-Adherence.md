# Center for Internet Security (CIS) Adherence

This document outlines the adherence of this repo to the Microsoft Azure Foundations Benchmark v2.0 - downloadable from the CIS website [here](https://downloads.cisecurity.org/).

## What does this document apply to?

This CIS adherence review primarily applies to a production subscription, where sensitive data is held and processed. For this repo, this would apply whenever this utility is used to bootstrap an environment that manages real data (i.e. `UCLH-Foundry/FlowEHR` in a `prod` subscription).

## Note on Maintenance of this Document

This document exists in this repo, and not elsewhere, in order to keep it closer to the resource definitions that it references, and easier to update as resources are added or changed. It is suggested that when a resource is added, this document is updated to reference the new resource and ensure that appropriate security settings have been applied to it.

Azure-Bootstrap is deployed using Terraform. Terraform maintains a text based state file in Azure Storage, which contains a number of keys and secrets, and should be treated as such. 

| Azure Resource | CIS Reference | Adherence | Notes |
|--|--|--|--|
| Azure Storage Account for FlowEHR management: <br/>`stgmgmt<suffix>` | `CIS 3` | [main.tf](./bootstrap/shared/management/main.tf) | Issues summarised https://github.com/UCLH-Foundry/FlowEHR/issues/176 / https://github.com/UCLH-Foundry/FlowEHR/issues/199 |
| | `CIS 3.1`: Ensure 'Secure Transfer Required' set to 'Enabled' | Y | |
| | `CIS 3.2`: Ensure 'Enable Infrastructure Encryption' set to 'Enabled' | Y |  |
| | `CIS 3.3`: Enable key rotation reminders for each storage account | N | Storage keys are not used for authentication |
| | `CIS 3.4`: Ensure that Storage Account Access keys are periodically regenerated | N | Storage keys are not used for authentication |
| | `CIS 3.7`: Ensure 'Public Access Level' is disabled | Y | |
| | `CIS 3.8`: Ensure Default Network Access Rule is set to 'Deny' | Y |  |
| | `CIS 3.9`: Ensure 'Trusted Azure Services' can access the storage account | Y |  |
| | `CIS 3.10`: Ensure Private Endpoints are used to access storage accounts | Y |  |
| | `CIS 3.11`: Ensure Soft Delete is enabled | Y |  |
| | `CIS 3.12`: Ensure storage is encrypted with Customer Managed Keys | N | Will use Microsoft Managed Keys to reduce management overhead |
| | `CIS: 3.13`: Ensure Storage Logging is enabled for 'read', 'write' and 'delete' requests | Y | | 
| | `CIS 3.15`: Ensure Minimum TLS Version is set to 1.2 | Y | |
