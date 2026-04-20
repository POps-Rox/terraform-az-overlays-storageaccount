# SCCA compliant Azure Storage Account Overlay with all storage account features

This example is to create a storage account with containers, SMB file shares, tables, queues, lifecycle management, private endpoints and other additional features.

## SCCA Compliance

This example is SCCA Compliant. For more information, please refer to the [SCCA Compliance]().

```hcl
# Azure Provider configuration
provider "azurerm" {
  features {}
}

module "mod_rg" {
  source = "POps-Rox/overlays-resource-group/azurerm"
  version = "~> 1.0.1"

  // Resource group name and location
  location       = var.location # This is the short location name (e.g. "eus")
  org_name       = "anoa"
  environment    = "dev"
  workload_name  = "test"
  use_location_short_name = true # This is to enable short location name (e.g. "eus") as part of the resource group name
  custom_rg_name = null

  // Enable resource locks
  enable_resource_locks = false
  lock_level            = ""

  // Add tags
  add_tags = {}
}

resource "azurerm_user_assigned_identity" "example" {
  for_each            = toset(["user-identity1", "user-identity2"])
  resource_group_name = module.mod_rg.resource_group_name
  location            = "eastus"
  name                = each.key
}

module "mod_storage" {
  source  = "POps-Rox/overlays-storage-account/azurerm"
  version = "~> 1.0.0"

  # By default, this module will not create a resource group
  # proivde a name to use an existing resource group, specify the existing resource group name, 
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG. 
  create_resource_group = true
  resource_group_name   = module.mod_rg.resource_group_name
  location              = "eastus"
  storage_account_name  = "storagedemo"

  # To enable advanced threat protection set argument to `true`
  enable_advanced_threat_protection = true

  # Container lists with access_type to create
  containers_list = [
    { name = "store250", access_type = "private" },
    { name = "blobstore251", access_type = "blob" },
    { name = "containter252", access_type = "container" }
  ]

  # SMB file share with quota (GB) to create
  file_shares = [
    { name = "smbfileshare1", quota = 50 },
    { name = "smbfileshare2", quota = 50 }
  ]

  # Storage tables
  tables = ["table1", "table2", "table3"]

  # Storage queues
  queues = ["queue1", "queue2"]

  # Enable Private Endpoint
  enable_private_endpoint = true
  existing_subnet_id = "existing-snet"

  # Configure managed identities to access Azure Storage (Optional)
  # Possible types are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`.
  managed_identity_type = "UserAssigned"
  managed_identity_ids  = [for k in azurerm_user_assigned_identity.example : k.id]

  # Lifecycle management for storage account.
  # Must specify the value to each argument and default is `0` 
  lifecycles = [
    {
      prefix_match               = ["store250/folder_path"]
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

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a variable. 
  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

## Terraform Usage

To run this example you need to execute following Terraform commands

```hcl
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.
