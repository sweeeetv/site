
resource "azurerm_storage_container" "visitor_counter_func_blob_container" {
  name                  = "${var.vc_api_name}-blob-container"
  storage_account_id = azurerm_storage_account.function_storage.id
  container_access_type = "private"
}

#------------------- function app resources -------------------#

//Function App on Consumption Plan (Linux) with Python runtime, using the new flex deployment model, which decouples the function app from the underlying hosting plan and allows more flexible scaling and configuration options. It also supports the latest Python runtime versions and has better cold start performance compared to the traditional consumption plan.
resource "azurerm_service_plan" "visitor_counter_plan" {
    name                = "${var.vc_api_name}_service_plan"
    resource_group_name = azurerm_resource_group.resume.name
    location            = var.location
    os_type             = "Linux"
    sku_name            = "FC1" 
    tags                = var.tags
}
resource "azurerm_function_app_flex_consumption" "visitor_counter_api" {
  name                = var.vc_api_name
  resource_group_name = azurerm_resource_group.resume.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.visitor_counter_plan.id

  # deployment storage, where the code and state will be stored. Blob Storage - a common choice for function app storage in the flex model.
  storage_container_type      = "blobContainer"
  //a public endpoint for the function app to access the blob, this is required for the flex plan to allow the function app to read/write code and state from the blob storage.
  storage_container_endpoint  = "${azurerm_storage_account.function_storage.primary_blob_endpoint}${azurerm_storage_container.visitor_counter_func_blob_container.name}"
    //the container is private, the access key is needed for authen, which is done in the next line with storage_authentication_type and storage_access_key.
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.function_storage.primary_access_key

  # Runtime python 3.13
  runtime_name    = "python"
  runtime_version = "3.13" 

  # Scale & memory max 100, memory 512
  maximum_instance_count = 2
  instance_memory_in_mb  = 512

  # environment variables for the function app. same as os.environ in python, these can be accessed in the function code to get the connection strings for application insights and cosmos db.
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.visitor_counter_appInsights.connection_string
    COSMOS_DB_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_cosmosdb_account.counter_db.name};AccountKey=${azurerm_cosmosdb_account.counter_db.primary_key};TableEndpoint=https://${azurerm_cosmosdb_account.counter_db.name}.table.cosmos.azure.com:443/;"
   }

  site_config {
    // a visitor's browser loads HTML, which has JS that calls the function app api, the browser includes Origin: https://pp.weirdcloud.dev header on that request automatically. The api replies back the same origin indicating it is allowed. The browser then allow the JS to process the reply.
    cors {
      allowed_origins = [
  //az app service, function cors doesn't support wildcard *
        "https://www.weirdcloud.dev", //this triggers the js, not pp
        "http://localhost:5500"
      ]
    }
  }
  lifecycle {
    ignore_changes = [
      site_config[0].cors
    ]
  }
}
#APM for the app, captures request traces, response times, exceptions, dependency calls and custom telemetry.
resource "azurerm_application_insights" "visitor_counter_appInsights" {
  name                = "${var.vc_api_name}-appInsights"
  resource_group_name = azurerm_resource_group.resume.name
  location            = var.location
  application_type     = "web"
  workspace_id = azurerm_log_analytics_workspace.for_all_insights.id
}

#where the insights logs stored. Use this to query the insights.
resource "azurerm_log_analytics_workspace" "for_all_insights" {
  name                = "workspace-for-all-insights"
  resource_group_name = azurerm_resource_group.resume.name
  location            = var.location
  sku                 = "PerGB2018"
    retention_in_days   = 30
  tags                = var.tags
}
