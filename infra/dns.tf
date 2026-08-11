#cf edge servers act as wc's authoratate dns ns.
#DNS operates below HTTP, no url, only resolves hostnames.
data "cloudflare_zone" "domain" {
  name = "weirdcloud.dev"
}

#-------------------- root, www -------------------------#
// test this if new subdomain is added:
// verify the apex so all the subdomains are verified:
// read blob.tf resource "azurerm_storage_account" "frontend" {... custom_domain {}} section.
# resource "cloudflare_record" "apex_verify" {
#   zone_id = data.cloudflare_zone.domain.id
#   name    = "asverify"
#   type    = "CNAME"
#   content = "asverify.storageacc444resume.z8.web.core.windows.net"
#   proxied = false 
# }
#create root domain
resource "cloudflare_record" "root" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "@"
  type    = "A"  
  content = "192.0.2.1" # Standard dummy IP used for CF redirects
  proxied = true 
  //false, CF acts as a routing table, returns Azure Storage FQDN directly to the client. The client connects directly to Azure.
  //true -> CF intercepts the traffic, and returns CF's own Anycast IPs to the client, terminates SSL at the edge, applies caching/WAF rules, and then proxies the request to Azure backend.
}

//2 ways to point apex to blob: 1) CNAME flattening. 2) Page Rule redirect.
//here uses page rule redirect, because CNAME flattening is not supported by all DNS providers, and CF's CNAME flattening is not compatible with Azure Storage blob's custom domain verification.
resource "cloudflare_page_rule" "redirect_root_to_www" {
  zone_id = data.cloudflare_zone.domain.id
  target  = "weirdcloud.dev/*" //catches all paths on apex
  status  = "active"

  actions  {
    forwarding_url  {
      status_code = 301 # Permanent Redirect, good for SEO. Tells Google "these are permanently the same page, count it all toward www."
      url   = "https://www.weirdcloud.dev/$1" //paste * from target into $1, so /foo/bar becomes https://www.weirdcloud.dev/foo/bar
    }
  }
}

#-------------------- www -------------------------#
resource "cloudflare_record" "www"{
  zone_id = data.cloudflare_zone.domain.id
  name = "www"
  type = "CNAME"
  content = azurerm_storage_account.frontend.primary_web_host
  proxied = true
}//needs blob to accept the custom domain in "azurerm_storage_account" or "InvalidUri 400", this is not a cors error.
resource "cloudflare_record" "www_verify" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "asverify.www" //validate first with zero downtime.
  type    = "CNAME"
  #CNAME that Azure provides for custom domain verification. 
  content = "asverify.storageacc444resume.z8.web.core.windows.net"
  proxied = false # Verification must be unproxied
}
#-------------------- api -------------------------#
resource "cloudflare_record" "api"{ //better to point the api to a custom domain too. although not necessary.
  zone_id = data.cloudflare_zone.domain.id
  name = "pp"
  type = "CNAME"
  content = azurerm_function_app_flex_consumption.visitor_counter_api.default_hostname //fqdn only-> [myaccount.z13.web.core.windows.net.], dns does not work at http level, no shema or url. eg. not https://myaccount.z13.web.core.windows.net/api/getresumecounter
  proxied = true
}
#The hidden TXT record to prove ownership to Azure

//asuid method, TXT, newer than asverify CNAME: separates the concepts of Routing and Proof of Ownership, instead use a cryptographic string (custom_domain_verification_id) that acts as a password.
resource "cloudflare_record" "api_verification" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "asuid.pp" #"asuid." prefix
  type    = "TXT"
  content = azurerm_function_app_flex_consumption.visitor_counter_api.custom_domain_verification_id // the token string Azure desgined for domain verification, does not change over time
  proxied = false # TXT records cannot be proxied
}
//custom domain binding
resource "azurerm_app_service_custom_hostname_binding" "api_binding" {
  hostname            = "pp.weirdcloud.dev"
  app_service_name    = azurerm_function_app_flex_consumption.visitor_counter_api.name
  resource_group_name = azurerm_resource_group.resume.name
  # Tell Terraform to wait for the TXT record to exist before binding
  depends_on = [
    time_sleep.wait_for_dns,
    cloudflare_record.api_verification,
    cloudflare_record.api //needs the CNAME to exist
    ] 
}
//this is so azure does not query the asuid.app TXT record before cloudflare set it up.
resource "time_sleep" "wait_for_dns" {
  depends_on = [cloudflare_record.api_verification]
  create_duration = "30s"
}
# resource "time_sleep" "wait_for_asverify" {
#   depends_on = [cloudflare_record.www_verify]
#   create_duration = "30s"
# }









#--------------------------------------------------------------------#
//not needed here
# # Force HTTPS to ALL of weirdcloud.dev, zone-wide.
# resource "cloudflare_zone_settings_override" "settings" {
#   zone_id = data.cloudflare_zone.domain.id
#   settings {
#     ssl            = "full" // 
#     always_use_https = "on" 
#     min_tls_version  = "1.2"
#   }
# }





//since anyone could bind a custom domain to the static web blob, add restrictions to blob access to from cf ip ranges only:
# resource "azurerm_storage_account_network_rules" "resume" {
#   storage_account_id = azurerm_storage_account.resume.id
#   default_action     = "Deny"
#   ip_rules           = [
#     # Cloudflare IPv4 ranges
#     "173.245.48.0/20",
#     "103.21.244.0/22",
#     "103.22.200.0/22",
#     "103.31.4.0/22",
#     "141.101.64.0/18",
#     "108.162.192.0/18",
#     "190.93.240.0/20",
#     "188.114.96.0/20",
#     "197.234.240.0/22",
#     "198.41.128.0/17",
#     "162.158.0.0/15",
#     "104.16.0.0/13",
#     "104.24.0.0/14",
#     "172.64.0.0/13",
#     "131.0.72.0/22"
#   ]
# }
//inconvenience for testing — if you curl https://youraccount.z13.web.core.windows.net from your mac terminal would return 403. 