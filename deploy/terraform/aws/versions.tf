terraform {
  # 1.11+ for write-only arguments, which keep the JWT secret out of the state file
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Local state by default. For anything shared, use an encrypted remote backend, e.g.:
  # backend "s3" {
  #   bucket       = "my-terraform-state"
  #   key          = "mm-events/aws.tfstate"
  #   region       = "ap-southeast-1"
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
