# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "popsrox_resource_name" "st" {
  name          = random_id.uniqueString.hex
  resource_type = "azurerm_storage_account"
  prefixes      = [var.org_name, var.use_location_short_name ? module.mod_azregions.location_short : module.mod_azregions.location_cli]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, var.workload_name, var.use_naming ? "" : "st"])
  use_slug      = var.use_naming
}