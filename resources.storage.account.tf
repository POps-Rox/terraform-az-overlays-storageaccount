# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#-------------------------------------------------------------
#  Storage Account Advanced Threat Protection configuration - Default is "false" 
#-------------------------------------------------------------
resource "azurerm_advanced_threat_protection" "atp" {
  count              = var.enable_advanced_threat_protection ? 1 : 0
  target_resource_id = azurerm_storage_account.storage.id
  enabled            = var.enable_advanced_threat_protection
}

#------------------------------------------------------------
# Storage Account Instance configuration - Default (required). 
#------------------------------------------------------------
resource "azurerm_storage_account" "storage" {
  name                = local.sa_name
  resource_group_name = local.resource_group_name
  location            = local.location

  access_tier              = var.account_kind == "BlockBlobStorage" && var.account_tier == "Premium" ? null : var.access_tier
  account_tier             = local.account_tier
  account_replication_type = local.account_replication_type
  account_kind             = var.account_kind

  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.public_nested_items_allowed
  shared_access_key_enabled       = var.shared_access_key_enabled
  # Large File Share is only available for Standard and Premium accounts
  # Large File Share is only available for LRS and ZRS replication types.
  # Large File Share is not available for BlockBlobStorage accounts.
  large_file_share_enabled = var.account_kind != "BlockBlobStorage" && contains(["LRS", "ZRS"], var.account_replication_type)

  sftp_enabled               = var.sftp_enabled
  nfsv3_enabled              = var.nfsv3_enabled
  is_hns_enabled             = var.nfsv3_enabled || var.sftp_enabled ? true : var.hns_enabled
  https_traffic_only_enabled = var.nfsv3_enabled ? false : var.https_traffic_only_enabled

  dynamic "identity" {
    for_each = var.identity_type == null ? [] : ["enabled"]
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids == "UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "static_website" {
    for_each = var.static_website_config == null ? [] : ["enabled"]
    content {
      index_document     = var.static_website_config.index_document
      error_404_document = var.static_website_config.error_404_document
    }
  }

  dynamic "custom_domain" {
    for_each = var.custom_domain_name != null ? ["enabled"] : []
    content {
      name          = var.custom_domain_name
      use_subdomain = var.use_subdomain
    }
  }

  dynamic "blob_properties" {
    for_each = (
      var.account_kind != "FileStorage" && (var.storage_blob_data_protection != null || var.storage_blob_cors_rule != null) ?
      ["enabled"] : []
    )

    content {
      change_feed_enabled = var.nfsv3_enabled ? false : var.storage_blob_data_protection.change_feed_enabled
      versioning_enabled  = var.nfsv3_enabled ? false : var.storage_blob_data_protection.versioning_enabled

      dynamic "cors_rule" {
        for_each = var.storage_blob_cors_rule != null ? ["enabled"] : []
        content {
          allowed_headers    = var.storage_blob_cors_rule.allowed_headers
          allowed_methods    = var.storage_blob_cors_rule.allowed_methods
          allowed_origins    = var.storage_blob_cors_rule.allowed_origins
          exposed_headers    = var.storage_blob_cors_rule.exposed_headers
          max_age_in_seconds = var.storage_blob_cors_rule.max_age_in_seconds
        }
      }

      dynamic "delete_retention_policy" {
        for_each = var.storage_blob_data_protection.delete_retention_policy_in_days > 0 ? ["enabled"] : []
        content {
          days = var.storage_blob_data_protection.delete_retention_policy_in_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = var.storage_blob_data_protection.container_delete_retention_policy_in_days > 0 ? ["enabled"] : []
        content {
          days = var.storage_blob_data_protection.container_delete_retention_policy_in_days
        }
      }

      dynamic "restore_policy" {
        for_each = local.pitr_enabled ? ["enabled"] : []
        content {
          days = var.storage_blob_data_protection.container_delete_retention_policy_in_days - 1
        }
      }
    }
  }

  dynamic "queue_properties" {
    for_each = var.queue_properties_logging != null && contains(["Storage", "StorageV2"], var.account_kind) && var.account_tier == "Premium" ? ["enabled"] : []
    content {
      logging {
        delete                = var.queue_properties_logging.delete
        read                  = var.queue_properties_logging.read
        write                 = var.queue_properties_logging.write
        version               = var.queue_properties_logging.version
        retention_policy_days = var.queue_properties_logging.retention_policy_days
      }
    }
  }

  dynamic "share_properties" {
    for_each = var.file_share_cors_rules != null || var.file_share_retention_policy_in_days != null || var.file_share_properties_smb != null ? ["enabled"] : []
    content {
      dynamic "cors_rule" {
        for_each = var.file_share_cors_rules != null ? ["enabled"] : []
        content {
          allowed_headers    = var.file_share_cors_rules.allowed_headers
          allowed_methods    = var.file_share_cors_rules.allowed_methods
          allowed_origins    = var.file_share_cors_rules.allowed_origins
          exposed_headers    = var.file_share_cors_rules.exposed_headers
          max_age_in_seconds = var.file_share_cors_rules.max_age_in_seconds
        }
      }

      dynamic "retention_policy" {
        for_each = var.file_share_retention_policy_in_days != null ? ["enabled"] : []
        content {
          days = var.file_share_retention_policy_in_days
        }
      }

      dynamic "smb" {
        for_each = var.file_share_properties_smb != null ? ["enabled"] : []
        content {
          authentication_types            = var.file_share_properties_smb.authentication_types
          channel_encryption_type         = var.file_share_properties_smb.channel_encryption_type
          kerberos_ticket_encryption_type = var.file_share_properties_smb.kerberos_ticket_encryption_type
          versions                        = var.file_share_properties_smb.versions
          multichannel_enabled            = var.file_share_properties_smb.multichannel_enabled
        }
      }
    }
  }

  dynamic "azure_files_authentication" {
    for_each = var.file_share_authentication != null ? ["enabled"] : []
    content {
      directory_type = var.file_share_authentication.directory_type
      dynamic "active_directory" {
        for_each = var.file_share_authentication.directory_type == "AD" ? [var.file_share_authentication.active_directory] : []
        iterator = ad
        content {
          storage_sid         = ad.value.storage_sid
          domain_name         = ad.value.domain_name
          domain_sid          = ad.value.domain_sid
          domain_guid         = ad.value.domain_guid
          forest_name         = ad.value.forest_name
          netbios_domain_name = ad.value.netbios_domain_name
        }
      }
    }
  }

  tags = merge({ "ResourceName" = format("%s", local.sa_name) }, local.default_tags, var.add_tags)
}
