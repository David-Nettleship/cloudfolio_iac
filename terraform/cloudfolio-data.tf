provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

data "archive_file" "cloudfolio-data-func" {
  type        = "zip"
  source_file = "../cloudfolio-data.py"
  output_path = "output/cloudfolio-data.zip"
}

resource "aws_dynamodb_table" "cloudfolio-data" {
  name           = "cloudfolio-data"
  billing_mode   = "PAY_PER_REQUEST"
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
  billing_mode   = "PAY_PER_REQUEST"
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

resource "aws_iam_role" "cloudfolio-data-lambda-iam-role" {
  name = "cf-data-lambda-role"

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

resource "aws_lambda_function" "cloudfolio-data-lambda" {
  filename         = "output/cloudfolio-data.zip"
  function_name    = "cloudfolio-data-lambda"
  source_code_hash = filebase64sha256("output/cloudfolio-data.zip")
  role             = aws_iam_role.cloudfolio-data-lambda-iam-role.arn
  handler          = "cloudfolio-data.lambda_handler"
  timeout          = 600
  runtime          = "python3.9"
}

resource "aws_cloudwatch_event_rule" "daily_cron" {
  name                = "daily_cron"
  description         = "Fires every day @00:00 UTC"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "check_daily_cron" {
  rule      = aws_cloudwatch_event_rule.daily_cron.name
  target_id = "cloudfolio-data-lambda"
  arn       = aws_lambda_function.cloudfolio-data-lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_daily_cron" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfolio-data-lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cron.arn
}