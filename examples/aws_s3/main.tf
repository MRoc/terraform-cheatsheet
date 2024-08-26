provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "finance" {
  bucket = "finance-acme-com"
}

resource "aws_s3_object" "pl2020" {
  content = "/root/finance/pl2020.docx"
  key = "finance-2020.docx"
  bucket = aws_s3_bucket.finance.id
}

resource "aws_iam_group" "finance-data" {
  name = "finance-analysts"
}

data "aws_iam_group" "finance-data" {
  group_name = "finance-analysts"
  depends_on = [
    aws_iam_group.finance-data
  ]
}

resource "aws_s3_bucket_policy" "finance-policy" {
  bucket = aws_s3_bucket.finance.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "*",
        "Effect": "Allow",
        "Resource": "arn:aws:s3::${aws_s3_bucket.finance.id}/*",
        "Principal": {
          "AWS": [
            "${aws_iam_group.finance-data.arn}"
          ]
        }
      }
    ]
  }
  EOF
}