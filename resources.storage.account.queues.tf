# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Storage Account Queues Creation 
#----------------------------------------------------------
resource "azurerm_storage_queue" "queue" {
  for_each = try({ for q in var.queues : q.name => q }, {})

  storage_account_id = azurerm_storage_account.storage.id

  name     = each.key
  metadata = each.value.metadata
}