# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------
# Local declarations
#---------------------------------
# The following block of locals are used to avoid using
# empty object types in the code
locals {
  empty_list   = []
  empty_map    = tomap({})
  empty_string = ""
}

#---------------------------------
# Random ID
#---------------------------------
resource "random_id" "uniqueString" {
  keepers = {
    # Generate a new id each time we change resourcePrefix variable
    org_prefix = var.org_name
    subid      = var.workload_name
  }
  byte_length = 5
}

locals {
  account_tier             = (var.account_kind == "FileStorage" ? "Premium" : split("_", var.sku_name)[0])
  account_replication_type = (local.account_tier == "Premium" ? "LRS" : split("_", var.sku_name)[1])

  pitr_enabled = (
    alltrue([var.storage_blob_data_protection.change_feed_enabled, var.storage_blob_data_protection.versioning_enabled, var.storage_blob_data_protection.container_point_in_time_restore])
    && var.storage_blob_data_protection.delete_retention_policy_in_days > 0
    && var.storage_blob_data_protection.container_delete_retention_policy_in_days > 2
    && !var.nfsv3_enabled
  )
}

# Telemetry is collected by creating an empty ARM deployment with a specific name
# If you want to disable telemetry, you can set the disable_telemetry variable to true

# The following locals identify the module
locals {
  org_name          = var.org_name
  disable_telemetry = var.disable_telemetry

  # PUID identifies the module
  telem_workload_puid = "434fc92b-dbc0-4770-8642-f611851881bd"
}

# The following `can()` is used for when disable_telemetry = true
locals {
  telem_random_hex = can(random_id.telem[0].hex) ? random_id.telem[0].hex : local.empty_string
}

# Here we create the ARM templates for the telemetry deployment
locals {
  telem_arm_subscription_template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [],
  "outputs": {
    "telemetry": {
      "type": "String",
      "value": "For more information, see https://aka.ms/POps-Rox/tf/telemetry"
    }
  }
}
TEMPLATE
}
