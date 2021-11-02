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
  hash_key       = "Ticker"
  range_key      = "Value"

  attribute {
    name = "Ticker"
    type = "S"
  }

  attribute {
    name = "Value"
    type = "N"
  }
}