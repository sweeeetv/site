resource "azurerm_storage_account" "frontend" {
  //name can only include lowercases and numbers
  name                     = "storageacc444resume"
  resource_group_name      = azurerm_resource_group.resume.name
  location                 = azurerm_resource_group.resume.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  tags                     = var.tags
    custom_domain {
    name          = "www.weirdcloud.dev"
    use_subdomain = true
  }
}

//Turns on Static Website hosting on blob and configures its landing page (index_document) and custom error page (error_404_document) — both set to index.html here.

resource "azurerm_storage_account_static_website" "resume" {
  storage_account_id = azurerm_storage_account.frontend.id
  error_404_document = "index.html" //use a 404.html 
  index_document     = "index.html" 
}//az resource list will not track this because it isn't an ARM resource and does not have its own ID.

resource "azurerm_storage_account" "function_storage" {
  name                     = "resumevisitorcounterapi"
  resource_group_name      = azurerm_resource_group.resume.name
  location                 = azurerm_resource_group.resume.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = var.tags 
}