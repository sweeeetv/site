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

//az resource list - will not track this because it is not an ARM resource and does not have its own ID.
resource "azurerm_storage_account_static_website" "resume" {
  storage_account_id = azurerm_storage_account.frontend.id
  error_404_document = "index.html"
  index_document     = "index.html"
}

resource "azurerm_storage_account" "function_storage" {
  name                     = "resumevisitorcounterapi"
  resource_group_name      = azurerm_resource_group.resume.name
  location                 = azurerm_resource_group.resume.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = var.tags 
}