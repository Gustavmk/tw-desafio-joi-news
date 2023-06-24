# Setup our aws provider
variable "region" {
  default = "eu-west-1"
}
provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "newskuno-terraform-infra"
    region = "eu-west-1"
    dynamodb_table = "newskuno-terraform-locks"
    key = "news/terraform.tfstate"
  }
}
