terraform {
  //recent Terraform version (1.10+)
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #latest major version (4.x)
      version = "~> 4.0"
    } 
    github = {
      source = "integrations/github"
      version = "~> 6.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    //for time_sleep in dns binding section
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    //for this project -> app registrations
    azuread = { //azure ad
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
#store the tfstate files in the blob provisioned for tf state files.
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatepersonalxgao"
    container_name       = "tfstate"
    key                  = "resume.terraform.tfstate"//the name of the tfstate file in the blob.
  }
} 
//terraform calls Azure API, authenticates against this subscription
provider "azurerm" {
  subscription_id = var.subscription_id
  features {
  }
}
provider "github" {
  owner = var.github_org
  token = var.github_token 
}

//for my domain name, I use Cloudflare as my DNS provider.
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}