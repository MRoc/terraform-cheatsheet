terraform {
  backend "s3" {
    bucket = "mroc-s3-terraform-lock"
    key = "folder/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "mroc-dynamodb-terraform-lock"
  }
}