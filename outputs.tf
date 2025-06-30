output "function_app_name" {
  value = azurerm_linux_function_app.func.name
}

output "log_table_name" {
  value = azurerm_storage_table.logtable.name
}
