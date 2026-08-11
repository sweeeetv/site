variable "project" {
  default = "resume"
}
variable "location" {
  default = "australiaeast"
}
variable "tags" {
  default = {
    project = "my-site"
    managed_by = "terraform"
  }
}

variable "vc_api_name" {
  default = "weirdcloud-visitor-counter-api"
}
variable "subscription_id"{
  type = string
}
variable "github_org" {
  type = string
}
variable "github_repo" {
  description = "site"
  type = string
}

variable "oidc_subject" { //oidc.tf
  type =string
}


# ------------ secrets -------------- #
variable "github_token" {
  description = "My GitHub Personal Access Token"
  type        = string
  sensitive   = true
}
variable "cloudflare_api_token" {
  type = string
  sensitive =true 
}