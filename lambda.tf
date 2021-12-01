locals {
  function_name = "alexa_helloworld"
  handler = "lambda.lambda_handler"
}

# ====================
#
# Archive
#
# ====================
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "app"
  output_path = "archive/${local.function_name}.zip"
}

# ====================
#
# Lambda
#
# ====================
resource "aws_lambda_function" "aws_function" {
  function_name = local.function_name
  handler       = local.handler
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.8"
  timeout       = 10
  kms_key_arn = aws_kms_key.lambda_key.arn

  filename         = data.archive_file.function_source.output_path
  source_code_hash = data.archive_file.function_source.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.lambda_policy, aws_cloudwatch_log_group.lambda_log_group]
}

# ====================
#
# IAM Role
#
# ====================
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_policy" {
  source_json = data.aws_iam_policy.lambda_basic_execution.policy

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "AWSlexaHelloLambdaPolicy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "lambda_role" {
  name               = "AWSAlexaHelloLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# ====================
#
# KMS
#
# ====================
resource "aws_kms_key" "lambda_key" {
  description             = "My Lambda Function Customer Master Key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/${local.function_name}"
  target_key_id = aws_kms_key.lambda_key.id
}

# ====================
#
# CloudWatch
#
# ====================
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${local.function_name}"
  retention_in_days = 30
}

# ====================
#
# Alexa Trigger
#
# ====================
resource "aws_lambda_permission" "with_alexa" {
  statement_id  = "AllowExecutionFromAlexa"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "alexa-appkit.amazon.com"
  event_source_token = "amzn1.ask.skill.59c6f728-b3d6-4e3b-abed-f9c13dce38a0"
}