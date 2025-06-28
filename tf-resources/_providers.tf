provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "cbe-blr-eks-rw"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "cbe-blr-eks-tf-state-dynamo-db"
    region         = "us-west-2"
  }
}
