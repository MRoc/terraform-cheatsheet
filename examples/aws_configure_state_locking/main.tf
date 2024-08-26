provider "aws" {
   region = "eu-central-1"
}

resource "aws_dynamodb_table" "mroc-dynamodb-terraform-lock" {
   name = "mroc-dynamodb-terraform-lock"
   hash_key = "LockID"
   billing_mode = "PAY_PER_REQUEST"

   attribute {
      name = "LockID"
      type = "S"
   }
}

resource "aws_s3_bucket" "mroc-s3-terraform-lock" {
  bucket = "mroc-s3-terraform-lock"
}