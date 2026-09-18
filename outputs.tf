# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "storage_account_properties" {
  description = "Created Storage Account properties"
  value       = azurerm_storage_account.storage
  sensitive   = true
}

output "storage_account_id" {
  description = "Created Storage Account ID"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Created Storage Account name"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_uri" {
  description = "Created Storage Account name"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Specifies the primary access key of the storage account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "storage_account_identity" {
  description = "Created Storage Account identity block"
  value       = azurerm_storage_account.storage.identity[0]
}

output "storage_account_principal_id" {
  description = "Created Storage Account principal id"
  value       = azurerm_storage_account.storage.identity[0].principal_id
}

output "storage_account_network_rules" {
  description = "Network rules of the associated Storage Account"
  value       = one(azurerm_storage_account_network_rules.network_rules[*])
}

output "storage_blob_containers" {
  description = "Created blob containers in the Storage Account"
  value       = azurerm_storage_container.container
}

output "primary_blob_endpoint" {
  description = "Specifies the primary blob endpoint of the storage account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "storage_file_shares" {
  description = "Created file shares in the Storage Account"
  value       = azurerm_storage_share.share
}

output "storage_file_tables" {
  description = "Created tables in the Storage Account"
  value       = azurerm_storage_table.table
}

output "storage_file_queues" {
  description = "Created queues in the Storage Account"
  value       = azurerm_storage_queue.queue
}
