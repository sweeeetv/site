resource "azurerm_cosmosdb_account" "counter_db" {
    name = "weirdcloud-counter-table-db"
    location = var.location
    resource_group_name = azurerm_resource_group.resume.name
    offer_type = "Standard"
    kind = "GlobalDocumentDB"
    automatic_failover_enabled = false
    public_network_access_enabled = true
  capabilities { 
    name = "EnableServerless" 
  }
  capabilities {
    name = "EnableTable"
  }
  consistency_policy {
    // Session consistency is a good balance between performance and consistency. It ensures that reads will see the most recent writes, while still offering better performance than stronger consistency levels.
    consistency_level = "Session"
  }
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }
  tags = var.tags
}
resource "azurerm_cosmosdb_table" "counter_table" {
  name                = "visitor-counter-table"
  resource_group_name = azurerm_resource_group.resume.name
  account_name        = azurerm_cosmosdb_account.counter_db.name
  #throughput not necessary for serverless accounts, if needed, then:
  #throughput          = 400
}
//define the contents of the db table in the python code, no need to set up here.