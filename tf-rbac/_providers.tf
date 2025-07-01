terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
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