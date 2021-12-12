
provider "aws" {
  region = "us-east-1"
}

 terraform {
  backend "s3" {
    bucket = "project1-s3"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
