locals {
  backend_lambda_name = var.environment
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.environment}-function"
  description   = "${var.environment} function to record data to DynamoDB"
  handler       = "backend.lambda_handler"
  publish       = true
  runtime       = "python3.11"
  timeout       = 30

  source_path = [
    {
      path = "${path.module}/backend"
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    bedrock_invoke = {
      effect  = "Allow",
      actions = ["dynamodb:*"],
      resources = [
        module.respondent_dynamo.dynamodb_table_arn,
        module.responses_dynamo.dynamodb_table_arn,
      ]
    },
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  cloudwatch_logs_retention_in_days = 3

  tags = var.tags
}