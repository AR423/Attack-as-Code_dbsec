terraform {
  backend "s3" {
    bucket         = "dbsec-tfstate-ar423"
    key            = "weak/terraform.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }

  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}