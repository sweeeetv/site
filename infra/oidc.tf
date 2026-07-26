
#fetch tenant id,  a specific data source that contains infos about the provider's configuration, including the tenant ID, object ID, and client ID of the authenticated service principal or managed identity ("Who is running this terraform right now?" - gh or local laptop' IDs).
data "azuread_client_config" "current" {}
#subscription
data "azurerm_subscription" "current" {}

#create the app registration - or an identity def (similar to a human user or a function app). One per app
resource "azuread_application" "github_cicd" { //it alone can't do anything, must be assigned with a service pricipal and assign roles.
    display_name = "github-personal-site"
}
#create a service principal for the app registration, the sp is the account. (eq. managed identity for function app)
resource "azuread_service_principal" "github_cicd" {
    client_id = azuread_application.github_cicd.client_id 
}
#create the federated cred
#only trust JWTs from this repo + branch
#basically tell azure how to verify the app reg/gihub repo that claims to be the app reg when gh actions workflow runs.
# 3 checks: issuer, subject, audience
resource "azuread_application_federated_identity_credential" "github_main" {
    application_id = azuread_application.github_cicd.id
    display_name = "github-site-main-branch"
#azure fetches gh's public key from this URL, to verify JWTs from gh
    issuer ="https://token.actions.githubusercontent.com" //1
    # must match what GitHub puts in the JWT
    subject  = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main" //2
    // audience is the app registration's client_id(azuread_application.github_cicd.client_id)
    //JWT contains an aud field. answers "who is this token for?"
    //3
    audiences = ["api://AzureADTokenExchange"] //a fixed string Microsoft and GitHub agreed on. lets GHA authenticate to Azure without a stored secret/password.
# Mental image:
#GA generates a short-lived JWT token, signed by GitHub, saying "I am run X of repo Y on branch Z."
#That JWT gets sent to Entra ID and exchanged for a real Azure access token.
# For Entra ID to agree to do that exchange, the incoming JWT must declare its intended audience as - api://AzureADTokenExchange — this is Microsoft's fixed string that means "this token is presenting itself to be traded in for an Entra ID token, nothing else."
}
//assign contributor role on the rg - what the identity allowed to do
resource "azurerm_role_assignment" "github_cicd_contributor"{
    scope = azurerm_resource_group.resume.id
    role_definition_name = "Contributor"
    principal_id = azuread_service_principal.github_cicd.object_id
}
//push the 3 ids:
resource "github_actions_secret" "client_id" {
    repository = var.github_repo
    secret_name = "AZURE_CLIENT_ID"
    plaintext_value = azuread_application.github_cicd.client_id // ID of the App Registration — a UUID that Azure generates when the resource is created
}
resource "github_actions_secret" "tenant_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azuread_client_config.current.tenant_id
}

resource "github_actions_secret" "subscription_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_subscription.current.subscription_id
}




## -----------Notes-------------- ##
# why cant the app reg be assigned with roles, needs service principal?
# Because, app regs are global objects, it lives in MS's global app registry not the tenant, since it does not fully exist in the tenant, then it can not be assigned with rbac roles. 
