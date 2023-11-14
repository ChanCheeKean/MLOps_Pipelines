# Terraform Block
terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.0"
    }
  }

  # save the statefile in remote location
  backend "s3" {
    bucket = "terraform"
    key    = "ml_infra/terraform.tfstate"
    region = "us-east-1"
  }
}

# Provider Block
provider "aws" {
  region  = var.region
  profile = "default"
}

/* 
terraform init
terraform fmt
terraform workspace new prod
terraform workspace list
terraform workspace select prod
terraform apply -auto-approve
terraform destroy
*/