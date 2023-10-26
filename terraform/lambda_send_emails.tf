locals {
  send_emails_lambda_name = "${var.environment}_send_emails"
}

module "lambda_function_send_emails" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${local.send_emails_lambda_name}_function"
  description   = "${local.send_emails_lambda_name} to send emails to recipients"
  handler       = "send_emails.lambda_handler"
  publish       = true
  runtime       = "python3.11"
  timeout       = 30

  environment_variables = {
    ADMIN_EMAIL       = "lee@bluesentry.cloud"
    BASE_URL          = "https://${local.site_domain}/"
    CREDENTIALS       = aws_secretsmanager_secret.this.name
    DYNAMO_RESPONDENT = module.respondent_dynamo.dynamodb_table_id
    EXCLUDED_EMAILS   = "admin@bluesentry.cloud, copier@bluesentryit.com, incidents@bluesentry.cloud, notifications@bluesentry.cloud, support@bluesentry.cloud"
    EXCLUDED_KEYWORDS = "archive, temp"
    SENDER            = local.email
  }

  source_path = [
    {
      path             = "${path.module}/send_emails"
      pip_requirements = true
    }
  ]

  attach_policies = true
  policies        = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  attach_policy_statements = true
  policy_statements = {
    dynamo = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = [module.respondent_dynamo.dynamodb_table_arn]
    },
    secrets = {
      effect = "Allow",
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:Get*",
        "secretsmanager:ListSecretVersionIds",
      ],
      resources = [aws_secretsmanager_secret.this.arn]
    },
    ses = {
      effect    = "Allow",
      actions   = ["ses:SendEmail"],
      resources = ["*"]
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