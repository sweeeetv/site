//after edit, run plan/apply again or terraform wont show them. (it only reads from .tfstate file)
output "website_url" {
  description = "/subscriptions/bcd4fe40-938d-48e2-bea9-6425a552c4ab/resourceGroups/rg-resume/providers/Microsoft.Storage/storageAccounts/storageacc444resume/blobServices/default"
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}

output "storage_account_id" {
  value = azurerm_storage_account.frontend.id
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.counter_db.endpoint
}

output "counter_api_endpoint"{
  value = azurerm_function_app_flex_consumption.visitor_counter_api.default_hostname
}





# output "cosmos_primary_key" {
#   value = azurerm_cosmosdb_account.counter_db.primary_master_key
#   sensitive = true
# }x