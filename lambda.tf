# Heroku Logging drain to AWS cloudwatch
# https://devcenter.heroku.com/articles/log-drains

# Converted from Cloudformation to Terraform from: 
# https://github.com/rwilcox/heroku_cloudwatch_sync

variable "heroku_cloudwatch_lambda_source_file" {
  default = "target/herokuCloudwatchSync.zip"
}

# Per: https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_cloudwatch_log_group" "yourapp_web_log_group" {
  name = "yourapp-web"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_stream" "yourapp_web_log_stream" {
  name           = "rails-production"
  log_group_name = aws_cloudwatch_log_group.yourapp_web_log_group.name
}

# Create the lambda function
resource "aws_lambda_function" "production_heroku_cloudwatch_sync" {
  function_name    = "heroku-cloudwatch-sync-production"
  filename         = var.heroku_cloudwatch_lambda_source_file
  source_code_hash = filebase64sha256(var.heroku_cloudwatch_lambda_source_file)
  handler     = "heroku_sync_to_cloudwatch.lambda_handler"
  role        = aws_iam_role.production_heroku_cloudwatch_lambda_exec.arn
  runtime     = "python3.6"
  memory_size = 512
  timeout     = 15

  depends_on = [
    aws_iam_role_policy_attachment.production_heroku_cloudwatch_sync_iam
  ]
}

# Permissions for the function
resource "aws_iam_role" "production_heroku_cloudwatch_lambda_exec" {
  name        = "serverless_production_heroku_cloudwatch_sync_lambda"
  description = "Heroku Cloudwatch Lambda AWS Lambda Execution Role"

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
}
resource "aws_iam_policy" "production_heroku_cloudwatch_policy" {
  name        = "serverless_production_heroku_cloudwatch_sync_policy"
  description = "Heroku Cloudwatch Lambda AWS Lambda Execution policy"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "production_heroku_cloudwatch_sync_iam" {
  role       = aws_iam_role.production_heroku_cloudwatch_lambda_exec.name
  policy_arn = aws_iam_policy.production_heroku_cloudwatch_policy.arn
}


# Permit this lambda to be invoked by the terraformed api_gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.production_heroku_cloudwatch_sync.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.execution_arn}/*/*"
}
