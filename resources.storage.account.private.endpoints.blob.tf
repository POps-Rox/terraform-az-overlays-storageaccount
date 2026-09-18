# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Storage Account Blob - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "blob_vnet" {
  count               = var.enable_blob_private_endpoint && var.virtual_network_name != null ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "blob_snet" {
  count                = var.enable_blob_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                 = var.existing_private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.blob_vnet.0.name
  resource_group_name  = local.resource_group_name
}

resource "azurerm_private_endpoint" "blob_pep" {
  count               = var.enable_blob_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                = format("%s-private-endpoint", azurerm_storage_account.storage.name)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.blob_snet.0.id
  tags                = merge({ "ResourceName" = format("%s-private-endpoint", azurerm_storage_account.storage.name) }, var.add_tags, )

  private_service_connection {
    name                           = "storageaccount-blob-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
  }
}

data "azurerm_private_endpoint_connection" "blob_pip" {
  count               = var.enable_blob_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.blob_pep.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_storage_account.storage]
}

resource "azurerm_private_dns_zone" "blob_dns_zone" {
  count               = var.existing_private_dns_zone == null && var.enable_blob_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.blob.core.windows.net" : "privatelink.blob.core.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "ResourceName" = format("%s", "StorageAccount-Blob-Private-DNS-Zone") }, var.add_tags, )
}

data "azurerm_private_dns_zone" "blob_dns_zone" {
  count               = var.existing_private_dns_zone != null && var.enable_blob_private_endpoint ? 1 : 0
  name                = var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_vnet_link" {
  count               = var.existing_private_dns_zone == null && var.enable_blob_private_endpoint ? 1 : 0
  name                = "blob-private-zone-link"
  private_dns_zone_id = azurerm_private_dns_zone.blob_dns_zone.0.id
  virtual_network_id  = data.azurerm_virtual_network.blob_vnet.0.id
  tags                = merge({ "ResourceName" = format("%s", "blob-private-zone-link") }, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "blob_a_record" {
  count               = var.enable_blob_private_endpoint ? 1 : 0
  name                = azurerm_storage_account.storage.name
  private_dns_zone_id = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.blob_dns_zone.0.id : data.azurerm_private_dns_zone.blob_dns_zone.0.id
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.blob_pip.0.private_service_connection.0.private_ip_address]
}
