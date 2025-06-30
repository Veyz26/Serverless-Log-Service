terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "f4e3112a-dc14-4dd1-b337-603a8c52c5f0" # Uncomment if needed
}

variable "location" {
  default = "South Africa North" # Change to a region with free trial support and quota
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                              = var.storage_account_name
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true
}

resource "azurerm_storage_table" "logtable" {
  name                 = "LogEntries"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_service_plan" "plan" {
  name                = "logServicePlan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1" # Use a free tier SKU for Function Apps
}

resource "azurerm_linux_function_app" "func" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  identity {
    type = "SystemAssigned"
  }
  site_config {
    always_on = true
  }
  app_settings = {
    "AzureWebJobsStorage" = azurerm_storage_account.storage.primary_connection_string
    "LogTableName"        = azurerm_storage_table.logtable.name
  }
}
