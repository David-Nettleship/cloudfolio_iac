provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

resource "aws_dynamodb_table" "cloudfolio-data" {
  name           = "cloudfolio-data"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Ticker"
  range_key      = "Quantity"

  attribute {
    name = "Ticker"
    type = "S"
  }

  attribute {
    name = "Quantity"
    type = "N"
  }
}

resource "aws_dynamodb_table" "cloudfolio-values" {
  name           = "cloudfolio-values"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Date"
  range_key      = "Ticker"

  attribute {
    name = "Date"
    type = "S"
  }

  attribute {
    name = "Ticker"
    type = "S"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  inline_policy {
      name = "UpdateVisitorCountDB"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["dynamodb:Scan", "dynamodb:PutItem"]
            Effect   = "Allow"
            Resource = [aws_dynamodb_table.cloudfolio-data.arn, aws_dynamodb_table.cloudfolio-values.arn]
          },
        ]
      })
    }
}