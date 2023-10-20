data "archive_file" "backend" {
  source_file = "${path.module}/backend/backend.py"
  output_path = "${path.module}/backend/backend.zip"
  type        = "zip"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "backend_lambda_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "backend_lambda_policy" {
  statement {
    actions   = ["dynamodb:*"]
    effect    = "Allow"
    resources = [module.backend_dynamo.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "backend_lambda_policy" {
  name   = "${var.environment}_backend_lambda_policy"
  policy = data.aws_iam_policy_document.backend_lambda_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_lambda_policy" {
  role       = aws_iam_role.lambda_execution_role_backend.name
  policy_arn = aws_iam_policy.backend_lambda_policy.arn
}

resource "aws_iam_role" "lambda_execution_role_backend" {
  name = "${var.environment}_backend_lambda_execution_role"

  assume_role_policy = data.aws_iam_policy_document.backend_lambda_execution_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_lambda_execution_policy" {
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
  role       = aws_iam_role.lambda_execution_role_backend.name
}

resource "aws_lambda_function" "backend" {
  filename      = data.archive_file.backend.output_path
  description   = "Store backend in DynamoDB"
  function_name = "${var.environment}_${local.backend_name}"
  role          = aws_iam_role.lambda_execution_role_backend.arn
  handler       = "${local.backend_name}.lambda_handler"
  runtime       = "python3.11"
  timeout       = 5

  environment {
    variables = {
      DYNAMO_REPONDENT = module.respondent_dynamo_dynamo.dynamodb_table_id
      DYNAMO_REPONSES  = module.responses_dynamo_dynamo.dynamodb_table_id
    }
  }

  source_code_hash = data.archive_file.backend.output_base64sha256

  tags = var.tags
}
