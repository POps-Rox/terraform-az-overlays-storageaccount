<!-- BADGES:START -->
[![CI](https://github.com/POps-Rox/tf-az-overlays-storageaccount/actions/workflows/ci.yml/badge.svg)](https://github.com/POps-Rox/tf-az-overlays-storageaccount/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/POps-Rox/tf-az-overlays-storageaccount/pulls)
[![Maintained](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/POps-Rox/tf-az-overlays-storageaccount/graphs/commit-activity)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-623CE4.svg?logo=terraform)](https://www.terraform.io)
<!-- BADGES:END -->

# Azure Storage Account Overlay

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-yellow.svg)](NOTICE) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE) [![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/POps-Rox/overlays-storage-account/azurerm/)

This Overlay terraform module can create a Storage Account with a set of containers (and access level), set of file shares (and quota), tables, queues, Network policies and Blob lifecycle management and manage related parameters (Threat protection, Network Rules, Private Endpoints, etc.) to be used in a [SCCA compliant Network](https://registry.terraform.io/modules/POps-Rox/overlays-management-hub/azurerm/latest).

To defines the kind of account, set the argument to account_kind = "StorageV2". Account kind defaults to StorageV2. If you want to change this value to other storage accounts kind, then this module automatically computes the appropriate values for account_tier, account_replication_type. The valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. static_website can only be set when the account_kind is set to StorageV2.

## SCCA Compliance

This module can be SCCA compliant and can be used in a SCCA compliant Network. Enable private endpoints and SCCA compliant network rules to make it SCCA compliant.

For more information, please read the [SCCA documentation]().

## Resources Supported

* [Storage Account](https://www.terraform.io/docs/providers/azurerm/r/storage_account.html)
* [Storage Advanced Threat Protection](https://www.terraform.io/docs/providers/azurerm/r/advanced_threat_protection.html)
* [Containers](https://www.terraform.io/docs/providers/azurerm/r/storage_container.html)
* [SMB File Shares](https://www.terraform.io/docs/providers/azurerm/r/storage_share.html)
* [Storage Table](https://www.terraform.io/docs/providers/azurerm/r/storage_table.html)
* [Storage Queue](https://www.terraform.io/docs/providers/azurerm/r/storage_queue.html)
* [Network Policies](https://www.terraform.io/docs/providers/azurerm/r/storage_account.html#network_rules)
* [Azure Blob storage lifecycle](https://www.terraform.io/docs/providers/azurerm/r/storage_management_policy.html)
* [Managed Service Identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#identity)

## Module Usage

```terraform
# Azurerm provider configuration
provider "azurerm" {
  features {}
}

```

## Resource Group

By default, this module will not create a resource group and the name of an existing resource group to be given in an argument `existing_resource_group_name`. If you want to create a new resource group, set the argument `create_resource_group = true`.

> [!NOTE]
> *If you are using an existing resource group, then this module uses the same resource group location to create all resources in this module.*

## Azure File Share Authentication

If you need to enable Active Directory or AAD DS authentication for Azure File on this Storage Account, please read the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable) and set the required values in the `file_share_authentication` variable.

## BlockBlobStorage accounts

A BlockBlobStorage account is a specialized storage account in the premium performance tier for storing unstructured object data as block blobs or append blobs. Compared with general-purpose v2 and BlobStorage accounts, BlockBlobStorage accounts provide low, consistent latency and higher transaction rates.

BlockBlobStorage accounts don't currently support tiering to hot, cool, or archive access tiers. This type of storage account does not support page blobs, tables, or queues.

To create BlockBlobStorage accounts, set the argument to `account_kind = "BlockBlobStorage"`.

## FileStorage accounts

A FileStorage account is a specialized storage account used to store and create premium file shares. This storage account kind supports files but not block blobs, append blobs, page blobs, tables, or queues.

FileStorage accounts offer unique performance dedicated characteristics such as IOPS bursting. For more information on these characteristics, see the File share storage tiers section of the Files planning guide.

To create BlockBlobStorage accounts, set the argument to `account_kind = "FileStorage"`.

## Containers

A container organizes a set of blobs, similar to a directory in a file system. A storage account can include an unlimited number of containers, and a container can store an unlimited number of blobs. The container name must be lowercase.

This module creates the containers based on your input within an Azure Storage Account.  Configure the `access_type` for this Container as per your preference. Possible values are `blob`, `container` or `private`. Preferred Defaults to `private`.

## SMB File Shares

Azure Files offers fully managed file shares in the cloud that are accessible via the industry standard Server Message Block (SMB) protocol. Azure file shares can be mounted concurrently by cloud or on-premises deployments of Windows, Linux, and macOS.

This module creates the SMB file shares based on your input within an Azure Storage Account.  Configure the `quota` for this file share as per your preference. The maximum size of the share, in gigabytes. For Standard storage accounts, this must be greater than `0` and less than `5120` GB (5 TB). For Premium FileStorage storage accounts, this must be greater than `100` GB and less than `102400` GB (100 TB).

## Soft delete for Blobs or Containers

Soft delete protects blob data from being accidentally or erroneously modified or deleted. When soft delete is enabled for a storage account, containers, blobs, blob versions, and snapshots in that storage account may be recovered after they are deleted, within a retention period that you specify.

This module allows you to specify the number of days that the blob or container should be retained period using `blob_soft_delete_retention_days` and `container_soft_delete_retention_days` arguments between 1 and 365 days. Default is `7` days.

> [!WARNING]
> Container soft delete can restore only whole containers and their contents at the time of deletion. You cannot restore a deleted blob within a container by using container soft delete. Microsoft recommends also enabling blob soft delete and blob versioning to protect individual blobs in a container.
>
> When you restore a container, you must restore it to its original name. If the original name has been used to create a new container, then you will not be able to restore the soft-deleted container.

## Configure Azure Storage firewalls and virtual networks

The Azure storage firewall provides access control access for the public endpoints of the storage account.  Use network policies to block all access through the public endpoint when using private endpoints. The storage firewall configuration also enables select trusted Azure platform services to access the storage account securely.

The default action set to `Allow` when no network rules matched. A `subnet_ids` or `ip_rules` can be added to `network_rules` block to allow a request that is not Azure Services.

```hcl
module "storage" {
  source  = "POps-Rox/tf-az-overlays-storage-account/azurerm"
  version = "x.x.x"

  # .... omitted

  # If specifying network_rules, one of either `ip_rules` or `subnet_ids` must be specified
  network_rules = {
    bypass     = ["AzureServices"]
    # One or more IP Addresses, or CIDR Blocks to access this Key Vault.
    ip_rules   = ["123.201.18.148"]
    # One or more Subnet ID's to access this Key Vault.
    subnet_ids = []
  }

  # .... omitted
  }
  ```

## Manage the Azure Blob storage lifecycle

Azure Blob storage lifecycle management offers a rich, rule-based policy for General Purpose v2 (GPv2) accounts, Blob storage accounts, and Premium Block Blob storage accounts. Use the policy to transition your data to the appropriate access tiers or expire at the end of the data's lifecycle.

The lifecycle management policy lets you:

* Transition blobs to a cooler storage tier (hot to cool, hot to archive, or cool to archive) to optimize for performance and cost
* Delete blobs at the end of their lifecycles
* Define rules to be run once per day at the storage account level
* Apply rules to containers or a subset of blobs*

This module supports the implementation of storage lifecycle management. If specifying network_rules, one of either `ip_rules` or `subnet_ids` must be specified and default_action must be set to `Deny`.

```hcl
module "storage" {
  source  = "POps-Rox/tf-az-overlays-storage-account/azurerm"
  version = "x.x.x"

  # .... omitted

  # Lifecycle management for storage account.
  # Must specify the value to each argument and default is `0`
  lifecycles = [
    {
      prefix_match               = ["mystore250/folder_path"]
      tier_to_cool_after_days    = 0
      tier_to_archive_after_days = 50
      delete_after_days          = 100
      snapshot_delete_after_days = 30
    },
    {
      prefix_match               = ["blobstore251/another_path"]
      tier_to_cool_after_days    = 0
      tier_to_archive_after_days = 30
      delete_after_days          = 75
      snapshot_delete_after_days = 30
    }
  ]

  # .... omitted
  }
  ```

## `Identity` - Configure managed identities to access Azure Storage

Managed identities for Azure resources provides Azure services with an automatically managed identity in Azure Active Directory. You can use this identity to authenticate to any service that supports Azure AD authentication, without having credentials in your code.

There are two types of managed identities:

* **System-assigned**: When enabled a system-assigned managed identity an identity is created in Azure AD that is tied to the lifecycle of that service instance. when the resource is deleted, Azure automatically deletes the identity. By design, only that Azure resource can use this identity to request tokens from Azure AD.
* **User-assigned**: A managed identity as a standalone Azure resource. For User-assigned managed identities, the identity is managed separately from the resources that use it.

Regardless of the type of identity chosen a managed identity is a service principal of a special type that may only be used with Azure resources. When the managed identity is deleted, the corresponding service principal is automatically removed.

```terraform
resource "azurerm_user_assigned_identity" "example" {
  for_each            = toset(["user-identity1", "user-identity2"])
  resource_group_name = "rg-shared-westeurope-01"
  location            = "westeurope"
  name                = each.key
}

module "storage" {
  source  = "POps-Rox/tf-az-overlays-storage-account/azurerm"
  version = "x.x.x"

  # .... omitted

  # Configure managed identities to access Azure Storage (Optional)
  # Possible types are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`.
  managed_identity_type = "UserAssigned"
  managed_identity_ids  = [for k in azurerm_user_assigned_identity.example : k.id]

# .... omitted for bravity

}
```

## Recommended naming and tagging conventions

Applying tags to your Azure resources, resource groups, and subscriptions to logically organize them into a taxonomy. Each tag consists of a name and a value pair. For example, you can apply the name `Environment` and the value `Production` to all the resources in production.
For recommendations on how to implement a tagging strategy, see Resource naming and tagging decision guide.

> [!IMPORTANT]
> Tag names are case-insensitive for operations. A tag with a tag name, regardless of the casing, is updated or retrieved. However, the resource provider might keep the casing you provide for the tag name. You'll see that casing in cost reports. **Tag values are case-sensitive.**

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production SharePoint workload is named like this: `pip-sharepoint-prod-westus-001`.

## Optional Features

Storage Account Overlay has optional features that can be enabled by setting parameters on the deployment.

## Create resource group

By default, this module will create a resource group and the name of the resource group to be given in an argument `resource_group_name` located in `variables.naming.tf`. If you want to use an existing resource group, specify the existing resource group name, and set the argument to `create_resource_group = false`.

> **Note:** *If you are using an existing resource group, then this module uses the same resource group location to create all resources in this module.*


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_popsrox-utils"></a> [popsrox-utils](#requirement\_popsrox-utils) | ~> 1.0.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.116 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_popsrox-utils"></a> [popsrox-utils](#provider\_popsrox-utils) | ~> 1.0.4 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.116 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mod_azure_region_lookup"></a> [mod\_azure\_region\_lookup](#module\_mod\_azure\_region\_lookup) | POps-Rox/overlays-azregions-lookup/azurerm | ~> 1.0.4 |

## Resources

| Name | Type |
|------|------|
| [azurerm_advanced_threat_protection.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/advanced_threat_protection) | resource |
| [azurerm_management_lock.resource_group_level_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_private_dns_a_record.a_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_storage_account.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.network_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_container.container](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_management_policy.lcpolicy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |
| [azurerm_storage_queue.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |
| [azurerm_storage_share.share](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_table.table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_table) | resource |
| [popsrox_utils_resource_name.sa](https://registry.terraform.io/providers/POps-Rox/popsrox-utils/latest/docs/data-sources/resource_name) | data source |
| [azurerm_private_endpoint_connection.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tier"></a> [access\_tier](#input\_access\_tier) | Defines the access tier for `BlobStorage`, `FileStorage` and `StorageV2` accounts. Valid options are `Hot` and `Cool`, defaults to `Hot`. | `string` | `"Hot"` | no |
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Changing this forces a new resource to be created. Defaults to StorageV2. | `string` | `"StorageV2"` | no |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Defines the type of replication to use for this Storage Account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`. | `string` | `"ZRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Defines the Tier to use for this Storage Account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created. | `string` | `"Standard"` | no |
| <a name="input_add_tags"></a> [add\_tags](#input\_add\_tags) | Map of custom tags. | `map(string)` | `{}` | no |
| <a name="input_advanced_threat_protection_enabled"></a> [advanced\_threat\_protection\_enabled](#input\_advanced\_threat\_protection\_enabled) | Boolean flag which controls if advanced threat protection is enabled, see [documentation](https://docs.microsoft.com/en-us/azure/storage/common/storage-advanced-threat-protection?tabs=azure-portal) for more information. | `bool` | `false` | no |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | List of CIDR to allow access to that Storage Account. | `list(string)` | `[]` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | List of objects to create some Blob containers in this Storage Account. | <pre>list(object({<br>    name                  = string<br>    container_access_type = optional(string)<br>    metadata              = optional(map(string))<br>  }))</pre> | `[]` | no |
| <a name="input_create_storage_account_resource_group"></a> [create\_storage\_account\_resource\_group](#input\_create\_storage\_account\_resource\_group) | Should the storage account be created in a separate resource group? | `bool` | `false` | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | The Custom Domain Name to use for the Storage Account, which will be validated by Azure. | `string` | `null` | no |
| <a name="input_default_firewall_action"></a> [default\_firewall\_action](#input\_default\_firewall\_action) | Which default firewalling policy to apply. Valid values are `Allow` or `Deny`. | `string` | `"Deny"` | no |
| <a name="input_default_tags_enabled"></a> [default\_tags\_enabled](#input\_default\_tags\_enabled) | Option to enable or disable default tags. | `bool` | `true` | no |
| <a name="input_deploy_environment"></a> [deploy\_environment](#input\_deploy\_environment) | Name of the workload's environnement | `string` | n/a | yes |
| <a name="input_enable_advanced_threat_protection"></a> [enable\_advanced\_threat\_protection](#input\_enable\_advanced\_threat\_protection) | Threat detection policy configuration, known in the API as Server Security Alerts Policy. Currently available only for the SQL API. | `bool` | `false` | no |
| <a name="input_enable_blob_private_endpoint"></a> [enable\_blob\_private\_endpoint](#input\_enable\_blob\_private\_endpoint) | Manages a Private Endpoint to Azure Storage Account for Blob | `bool` | `false` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | (Optional) Enable resource locks | `bool` | `false` | no |
| <a name="input_enable_table_private_endpoint"></a> [enable\_table\_private\_endpoint](#input\_enable\_table\_private\_endpoint) | Manages a Private Endpoint to Azure Storage Account for Tables | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The Terraform backend environment e.g. public or usgovernment | `string` | n/a | yes |
| <a name="input_existing_private_dns_zone"></a> [existing\_private\_dns\_zone](#input\_existing\_private\_dns\_zone) | Name of the existing private DNS zone | `any` | `null` | no |
| <a name="input_existing_subnet_id"></a> [existing\_subnet\_id](#input\_existing\_subnet\_id) | ID of the existing subnet | `any` | `null` | no |
| <a name="input_file_share_authentication"></a> [file\_share\_authentication](#input\_file\_share\_authentication) | Storage Account file shares authentication configuration. | <pre>object({<br>    directory_type = string<br>    active_directory = optional(object({<br>      storage_sid         = string<br>      domain_name         = string<br>      domain_sid          = string<br>      domain_guid         = string<br>      forest_name         = string<br>      netbios_domain_name = string<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_file_share_cors_rules"></a> [file\_share\_cors\_rules](#input\_file\_share\_cors\_rules) | Storage Account file shares CORS rule. Please refer to the [documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#cors_rule) for more information. | <pre>object({<br>    allowed_headers    = list(string)<br>    allowed_methods    = list(string)<br>    allowed_origins    = list(string)<br>    exposed_headers    = list(string)<br>    max_age_in_seconds = number<br>  })</pre> | `null` | no |
| <a name="input_file_share_properties_smb"></a> [file\_share\_properties\_smb](#input\_file\_share\_properties\_smb) | Storage Account file shares smb properties. | <pre>object({<br>    versions                        = optional(list(string), null)<br>    authentication_types            = optional(list(string), null)<br>    kerberos_ticket_encryption_type = optional(list(string), null)<br>    channel_encryption_type         = optional(list(string), null)<br>    multichannel_enabled            = optional(bool, null)<br>  })</pre> | `null` | no |
| <a name="input_file_share_retention_policy_in_days"></a> [file\_share\_retention\_policy\_in\_days](#input\_file\_share\_retention\_policy\_in\_days) | Storage Account file shares retention policy in days. | `number` | `null` | no |
| <a name="input_file_shares"></a> [file\_shares](#input\_file\_shares) | List of objects to create some File Shares in this Storage Account. | <pre>list(object({<br>    name             = string<br>    quota_in_gb      = number<br>    enabled_protocol = optional(string)<br>    metadata         = optional(map(string))<br>    acl = optional(list(object({<br>      id          = string<br>      permissions = string<br>      start       = optional(string)<br>      expiry      = optional(string)<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_hns_enabled"></a> [hns\_enabled](#input\_hns\_enabled) | Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 and must be `true` if `nfsv3_enabled` is set to `true`. Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_https_traffic_only_enabled"></a> [https\_traffic\_only\_enabled](#input\_https\_traffic\_only\_enabled) | Boolean flag which forces HTTPS if enabled. | `bool` | `true` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list of User Assigned Managed Identity IDs to be assigned to this Storage Account. | `list(string)` | `null` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). | `string` | `"SystemAssigned"` | no |
| <a name="input_lifecycles"></a> [lifecycles](#input\_lifecycles) | Configure Azure Storage firewalls and virtual networks | `list(object({ prefix_match = set(string), tier_to_cool_after_days = number, tier_to_archive_after_days = number, delete_after_days = number, snapshot_delete_after_days = number }))` | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which instance will be hosted | `string` | n/a | yes |
| <a name="input_lock_level"></a> [lock\_level](#input\_lock\_level) | (Optional) id locks are enabled, Specifies the Level to be used for this Lock. | `string` | `"CanNotDelete"` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | The minimum supported TLS version for the Storage Account. Possible values are `TLS1_0`, `TLS1_1`, and `TLS1_2`. | `string` | `"TLS1_2"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Optional prefix for the generated name | `string` | `""` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Optional suffix for the generated name | `string` | `""` | no |
| <a name="input_network_bypass"></a> [network\_bypass](#input\_network\_bypass) | Specifies whether traffic is bypassed for 'Logging', 'Metrics', 'AzureServices' or 'None'. | `list(string)` | <pre>[<br>  "Logging",<br>  "Metrics",<br>  "AzureServices"<br>]</pre> | no |
| <a name="input_network_rules_enabled"></a> [network\_rules\_enabled](#input\_network\_rules\_enabled) | Boolean to enable Network Rules on the Storage Account, requires `network_bypass`, `allowed_cidrs`, `subnet_ids` or `default_firewall_action` correctly set if enabled. | `bool` | `true` | no |
| <a name="input_nfsv3_enabled"></a> [nfsv3\_enabled](#input\_nfsv3\_enabled) | Is NFSv3 protocol enabled? Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | Name of the organization | `string` | n/a | yes |
| <a name="input_public_nested_items_allowed"></a> [public\_nested\_items\_allowed](#input\_public\_nested\_items\_allowed) | Allow or disallow nested items within this Account to opt into being public. | `bool` | `false` | no |
| <a name="input_queue_properties_logging"></a> [queue\_properties\_logging](#input\_queue\_properties\_logging) | Logging queue properties | <pre>object({<br>    delete                = optional(bool, true)<br>    read                  = optional(bool, true)<br>    write                 = optional(bool, true)<br>    version               = optional(string, "1.0")<br>    retention_policy_days = optional(number, 10)<br>  })</pre> | `{}` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | List of objects to create some Queues in this Storage Account. | <pre>list(object({<br>    name     = string<br>    metadata = optional(map(string))<br>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the workload ressource group | `string` | n/a | yes |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Indicates whether the Storage Account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). | `bool` | `true` | no |
| <a name="input_static_website_config"></a> [static\_website\_config](#input\_static\_website\_config) | Static website configuration. Can only be set when the `account_kind` is set to `StorageV2` or `BlockBlobStorage`. | <pre>object({<br>    index_document     = optional(string)<br>    error_404_document = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_storage_account_custom_name"></a> [storage\_account\_custom\_name](#input\_storage\_account\_custom\_name) | Custom Azure Storage Account name, generated if not set | `string` | `""` | no |
| <a name="input_storage_blob_cors_rule"></a> [storage\_blob\_cors\_rule](#input\_storage\_blob\_cors\_rule) | Storage Account blob CORS rule. Please refer to the [documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#cors_rule) for more information. | <pre>object({<br>    allowed_headers    = list(string)<br>    allowed_methods    = list(string)<br>    allowed_origins    = list(string)<br>    exposed_headers    = list(string)<br>    max_age_in_seconds = number<br>  })</pre> | `null` | no |
| <a name="input_storage_blob_data_protection"></a> [storage\_blob\_data\_protection](#input\_storage\_blob\_data\_protection) | Storage account blob Data protection parameters. | <pre>object({<br>    change_feed_enabled                       = optional(bool, false)<br>    versioning_enabled                        = optional(bool, false)<br>    delete_retention_policy_in_days           = optional(number, 0)<br>    container_delete_retention_policy_in_days = optional(number, 0)<br>    container_point_in_time_restore           = optional(bool, false)<br>  })</pre> | <pre>{<br>  "change_feed_enabled": true,<br>  "container_delete_retention_policy_in_days": 30,<br>  "container_point_in_time_restore": true,<br>  "delete_retention_policy_in_days": 30,<br>  "versioning_enabled": true<br>}</pre> | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets to allow access to that Storage Account. | `list(string)` | `[]` | no |
| <a name="input_tables"></a> [tables](#input\_tables) | List of objects to create some Tables in this Storage Account. | <pre>list(object({<br>    name = string<br>    acl = optional(list(object({<br>      id          = string<br>      permissions = string<br>      start       = optional(string)<br>      expiry      = optional(string)<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_use_naming"></a> [use\_naming](#input\_use\_naming) | Use the Azure NoOps naming provider to generate default resource name. `storage_account_custom_name` override this if set. Legacy default name is used if this is set to `false`. | `bool` | `true` | no |
| <a name="input_use_subdomain"></a> [use\_subdomain](#input\_use\_subdomain) | Should the Custom Domain Name be validated by using indirect CNAME validation? | `bool` | `false` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network | `string` | `""` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Name of the workload\_name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | Created Storage Account ID |
| <a name="output_storage_account_identity"></a> [storage\_account\_identity](#output\_storage\_account\_identity) | Created Storage Account identity block |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Created Storage Account name |
| <a name="output_storage_account_network_rules"></a> [storage\_account\_network\_rules](#output\_storage\_account\_network\_rules) | Network rules of the associated Storage Account |
| <a name="output_storage_account_properties"></a> [storage\_account\_properties](#output\_storage\_account\_properties) | Created Storage Account properties |
| <a name="output_storage_account_uri"></a> [storage\_account\_uri](#output\_storage\_account\_uri) | Created Storage Account name |
| <a name="output_storage_blob_containers"></a> [storage\_blob\_containers](#output\_storage\_blob\_containers) | Created blob containers in the Storage Account |
| <a name="output_storage_file_queues"></a> [storage\_file\_queues](#output\_storage\_file\_queues) | Created queues in the Storage Account |
| <a name="output_storage_file_shares"></a> [storage\_file\_shares](#output\_storage\_file\_shares) | Created file shares in the Storage Account |
| <a name="output_storage_file_tables"></a> [storage\_file\_tables](#output\_storage\_file\_tables) | Created tables in the Storage Account |
| <a name="output_terraform_module"></a> [terraform\_module](#output\_terraform\_module) | Information about this Terraform module |
<!-- END_TF_DOCS -->