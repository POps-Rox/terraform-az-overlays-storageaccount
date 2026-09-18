# Functional tests for the storage account overlay.
#
# These use mock_provider, so they execute WITHOUT Azure credentials and are
# safe to run on pull requests from forks in a public repository.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
      name     = "rg-existing"
      location = "eastus2"
    }
  }

  mock_data "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-test"
      name = "vnet-test"
    }
  }

  mock_data "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-private"
    }
  }

  mock_data "azurerm_private_endpoint_connection" {
    defaults = {
      private_service_connection = [{
        private_ip_address = "10.0.0.4"
      }]
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Storage/storageAccounts/generatedsa"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }

  mock_resource "azurerm_storage_table" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Storage/storageAccounts/generatedsa/tableServices/default/tables/auditevents"
    }
  }
}

mock_provider "azapi" {}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generatedsa"
    }
  }
}

variables {
  location                     = "eastus"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "orders"
  org_name                     = "anoa"
  existing_resource_group_name = "rg-existing"
}

run "generated_name_is_used_when_no_custom_name_given" {
  command = apply

  assert {
    condition     = azurerm_storage_account.storage.name == "generatedsa"
    error_message = "Expected the generated popsrox storage account name when storage_account_custom_name is unset, got: ${azurerm_storage_account.storage.name}"
  }
}

run "custom_storage_account_name_overrides_generated_name" {
  command = apply

  variables {
    storage_account_custom_name = "explicitstorage"
  }

  assert {
    condition     = azurerm_storage_account.storage.name == "explicitstorage"
    error_message = "storage_account_custom_name must take precedence over the generated name, got: ${azurerm_storage_account.storage.name}"
  }
}

run "empty_custom_storage_account_name_falls_through_to_generated_name" {
  command = apply

  variables {
    storage_account_custom_name = ""
  }

  assert {
    condition     = azurerm_storage_account.storage.name == "generatedsa"
    error_message = "An empty storage_account_custom_name must fall through to the generated name, got: ${azurerm_storage_account.storage.name}"
  }
}

run "conditional_resources_are_absent_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 0
    error_message = "enable_resource_locks defaults to false, so no management lock should be planned"
  }

  assert {
    condition     = length(azurerm_advanced_threat_protection.atp) == 0
    error_message = "enable_advanced_threat_protection defaults to false, so no advanced threat protection resource should be planned"
  }

  assert {
    condition     = length(azurerm_private_endpoint.blob_pep) == 0
    error_message = "enable_blob_private_endpoint defaults to false, so no blob private endpoint should be planned"
  }

  assert {
    condition     = length(azurerm_storage_account_static_website.static_website) == 0
    error_message = "static_website_config defaults to null, so no static website resource should be planned"
  }
}

run "enabled_conditionals_create_expected_resources" {
  command = apply

  variables {
    enable_resource_locks             = true
    enable_advanced_threat_protection = true
    enable_blob_private_endpoint      = true
    existing_private_subnet_name      = "snet-private"
    virtual_network_name              = "vnet-test"
    static_website_config = {
      index_document     = "index.html"
      error_404_document = "404.html"
    }
  }

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 1
    error_message = "enable_resource_locks = true must create exactly one management lock"
  }

  assert {
    condition     = length(azurerm_advanced_threat_protection.atp) == 1
    error_message = "enable_advanced_threat_protection = true must create exactly one advanced threat protection resource"
  }

  assert {
    condition     = length(azurerm_private_endpoint.blob_pep) == 1
    error_message = "enable_blob_private_endpoint with subnet and vnet names must create exactly one blob private endpoint"
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.blob_vnet_link) == 1
    error_message = "A managed blob private DNS zone should be linked to the VNet when no existing zone is supplied"
  }

  assert {
    condition     = length(azurerm_storage_account_static_website.static_website) == 1
    error_message = "static_website_config must create exactly one storage account static website resource"
  }

  assert {
    condition     = azurerm_storage_account_static_website.static_website[0].index_document == "index.html"
    error_message = "static website index_document must pass through from static_website_config"
  }
}

run "caller_supplied_tags_are_merged_in" {
  command = apply

  variables {
    add_tags = {
      costCenter = "cc-1234"
      owner      = "platform"
    }
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["ResourceName"] == "generatedsa"
    error_message = "The storage account ResourceName tag should be derived from local.sa_name"
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["costCenter"] == "cc-1234"
    error_message = "Tags passed via add_tags must appear on the storage account"
  }

  assert {
    condition     = azurerm_storage_account.storage.tags["env"] == "dev"
    error_message = "Default tags should include deploy_environment as env when default_tags_enabled is true"
  }
}

run "existing_resource_group_location_is_used_for_storage_account" {
  command = apply

  assert {
    condition     = azurerm_storage_account.storage.location == "eastus2"
    error_message = "The storage account location must come from the selected existing resource group, got: ${azurerm_storage_account.storage.location}"
  }
}
