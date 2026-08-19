terraform {
  # terraform_data is built into Terraform >= 1.4 and every version of OpenTofu.
  required_version = ">= 1.4"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
