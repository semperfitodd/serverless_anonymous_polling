terraform {
  backend "s3" {
    bucket = "bsc.sandbox.terraform.state"
    key    = "serverless_polling/terraform.tfstate"
    region = "us-east-2"
  }
}