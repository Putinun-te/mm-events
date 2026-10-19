terraform {
  # 1.11+ for write-only arguments, which keep the passwords out of the state file
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }

  # Local state by default. For anything shared, use an encrypted remote backend, e.g.:
  # backend "azurerm" {
  #   resource_group_name  = "tfstate"
  #   storage_account_name = "mytfstate"
  #   container_name       = "tfstate"
  #   key                  = "mm-events/azure.tfstate"
  # }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      # Soft-deleted vaults and secrets are purged on destroy, so the demo can be recreated
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
