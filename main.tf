provider "aws" {
  profile = var.profile
  region  = var.region
}

terraform {
  required_version = ">=1.0.11"
  backend "s3" {
    profile = "terraform"
    region  = "ap-northeast-1"
    bucket  = "runble1-tfstate"
    key     = "alexa-hello/terraform.tfstate"
    encrypt = true
  }
}
