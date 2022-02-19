provider "aws" {
  region = "ap-northeast-1"
  profile = "default"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.0.0"
    }
  }

  backend "s3" {
    bucket = "prototype-ioc-terraform"
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}

module "cognito" {
  source = "./cognito"

  user_pool_client = "sample_user_client"
  user_pool_name = "sample_user_pool"
  iam_for_lambda_name = "sample_iam_for_lambda"
  env = "dev"
}