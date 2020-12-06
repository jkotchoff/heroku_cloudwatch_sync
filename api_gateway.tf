# Expose an API Gateway for the Heroku AWS cloudwatch lambda syncing function
# https://github.com/rwilcox/heroku_cloudwatch_sync
# https://stackoverflow.com/questions/39040739/in-terraform-how-do-you-specify-an-api-gateway-endpoint-with-a-variable-in-the
# https://github.com/rwilcox/heroku_cloudwatch_sync
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration

resource "aws_api_gateway_rest_api" "heroku_cloudwatch_api_gateway" {
  name        = "heroku-cloudwatch-sync-production"
  description = "Terraform Serverless Cloudwatch Application"
}

resource "aws_api_gateway_deployment" "heroku_cloudwatch_gateway_deployment" {
  depends_on  = [aws_api_gateway_integration.flush_heroku_logs]
  rest_api_id = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  stage_name  = "Prod"
}

resource "aws_api_gateway_resource" "lambda_proxy" {
  rest_api_id = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.root_resource_id
  path_part = "flush"
}

resource "aws_api_gateway_resource" "log_group" {
  rest_api_id = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  parent_id   = aws_api_gateway_resource.lambda_proxy.id
  path_part   = "{logGroup}"
}

resource "aws_api_gateway_resource" "log_stream" {
  rest_api_id = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  parent_id   = aws_api_gateway_resource.log_group.id
  path_part   = "{logStream}"
}

resource "aws_api_gateway_method" "get-account" {
  rest_api_id = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  resource_id = aws_api_gateway_resource.log_stream.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.logGroup"  = true
    "method.request.path.logStream" = true
  }
}

resource "aws_api_gateway_integration" "flush_heroku_logs" {
  rest_api_id             = aws_api_gateway_rest_api.heroku_cloudwatch_api_gateway.id
  resource_id             = aws_api_gateway_resource.log_stream.id
  http_method             = aws_api_gateway_method.get-account.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  connection_type         = "INTERNET"
  uri                  = aws_lambda_function.production_heroku_cloudwatch_sync.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  request_parameters = {
    "integration.request.path.logGroup"  = "method.request.path.logGroup"
    "integration.request.path.logStream" = "method.request.path.logStream"
  }
}

output "base_url" {
  value = aws_api_gateway_deployment.heroku_cloudwatch_gateway_deployment.invoke_url
}

# heroku drains:add https://ABCD1234.execute-api.us-west-2.amazonaws.com/Prod/flush/yourapp-web/rails-production