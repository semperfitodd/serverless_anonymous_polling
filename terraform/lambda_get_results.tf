locals {
  get_results_lambda_name = "${var.environment}_get_results"
}

module "lambda_function_get_results" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.get_results_lambda_name}_function"
  description   = "${local.get_results_lambda_name} function to retrieve data to DynamoDB"
  handler       = "get_results.lambda_handler"
  publish       = true
  runtime       = "python3.11"
  timeout       = 30

  environment_variables = {
    "DYNAMO_RESPONDENT" = module.respondent_dynamo.dynamodb_table_id
    "DYNAMO_RESPONSES"  = module.responses_dynamo.dynamodb_table_id
  }

  source_path = [
    {
      path = "${path.module}/get_results"
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    dynamo = {
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