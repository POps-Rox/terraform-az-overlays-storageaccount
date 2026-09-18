# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Storage Account Tables Creation
#----------------------------------------------------------
resource "azurerm_storage_table" "table" {
  for_each = try({ for t in var.tables : t.name => t }, {})

  storage_account_id = azurerm_storage_account.storage.id

  name = each.key

  dynamic "acl" {
    for_each = each.value.acl != null ? each.value.acl : []

    content {
      id = acl.value.id

      access_policy {
        permissions = acl.value.permissions
        start       = acl.value.start
        expiry      = acl.value.expiry
      }
    }
  }
}