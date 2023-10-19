data "archive_file" "respondent" {
  source_file = "${path.module}/respondent/respondent.py"
  output_path = "${path.module}/respondent/respondent.zip"
  type        = "zip"
}

data "aws_iam_policy_document" "respondent_lambda_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "respondent_lambda_policy" {
  statement {
    actions   = ["dynamodb:*"]
    effect    = "Allow"
    resources = [module.respondent_dynamo.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "respondent_lambda_policy" {
  name   = "${var.environment}_respondent_lambda_policy"
  policy = data.aws_iam_policy_document.respondent_lambda_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "respondent_lambda_policy" {
  role       = aws_iam_role.lambda_execution_role_respondent.name
  policy_arn = aws_iam_policy.respondent_lambda_policy.arn
}

resource "aws_iam_role" "lambda_execution_role_respondent" {
  name = "${var.environment}_respondent_lambda_execution_role"

  assume_role_policy = data.aws_iam_policy_document.respondent_lambda_execution_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "respondent_lambda_execution_policy" {
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
  role       = aws_iam_role.lambda_execution_role_respondent.name
}

resource "aws_lambda_function" "respondent" {
  filename      = data.archive_file.respondent.output_path
  description   = "Store respondent in DynamoDB"
  function_name = "${var.environment}_${local.respondent_name}"
  role          = aws_iam_role.lambda_execution_role_respondent.arn
  handler       = "${local.respondent_name}.lambda_handler"
  runtime       = "python3.11"
  timeout       = 5

  environment {
    variables = {
      ENVIRONMENT  = module.respondent_dynamo.dynamodb_table_id
    }
  }

  source_code_hash = data.archive_file.respondent.output_base64sha256

  tags = var.tags
}
