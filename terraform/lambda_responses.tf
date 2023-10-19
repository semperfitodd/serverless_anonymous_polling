data "archive_file" "responses" {
  source_file = "${path.module}/responses/responses.py"
  output_path = "${path.module}/responses/responses.zip"
  type        = "zip"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "responses_lambda_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "responses_lambda_policy" {
  statement {
    actions   = ["dynamodb:*"]
    effect    = "Allow"
    resources = [module.responses_dynamo.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "responses_lambda_policy" {
  name   = "${var.environment}_responses_lambda_policy"
  policy = data.aws_iam_policy_document.responses_lambda_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "responses_lambda_policy" {
  role       = aws_iam_role.lambda_execution_role_responses.name
  policy_arn = aws_iam_policy.responses_lambda_policy.arn
}

resource "aws_iam_role" "lambda_execution_role_responses" {
  name = "${var.environment}_responses_lambda_execution_role"

  assume_role_policy = data.aws_iam_policy_document.responses_lambda_execution_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "responses_lambda_execution_policy" {
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
  role       = aws_iam_role.lambda_execution_role_responses.name
}

resource "aws_lambda_function" "responses" {
  filename      = data.archive_file.responses.output_path
  description   = "Store responses in DynamoDB"
  function_name = "${var.environment}_${local.responses_name}"
  role          = aws_iam_role.lambda_execution_role_responses.arn
  handler       = "${local.responses_name}.lambda_handler"
  runtime       = "python3.11"
  timeout       = 5

  environment {
    variables = {
      ENVIRONMENT  = module.responses_dynamo.dynamodb_table_id
    }
  }

  source_code_hash = data.archive_file.responses.output_base64sha256

  tags = var.tags
}
