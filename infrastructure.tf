terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile                 = "default"
  region                  = "us-east-1"
  shared_credentials_file = "/home/mike/.aws/credentials"
}

data "aws_iam_policy_document" "lambda_canary_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Lambda role
resource "aws_iam_role" "canary_lambda_role" {
  name               = "canary-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_canary_assume_role.json}"
}

locals {
  function_name = "canary-lambda"
}

# Lambda permissions to log to cloudwatch
resource "aws_cloudwatch_log_group" "canary_lambda_log_group" {
  name = "/aws/lambda/${local.function_name}"
}

data "aws_iam_policy_document" "cloudwatch_role_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]

    resources = ["${aws_cloudwatch_log_group.canary_lambda_log_group.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.canary_lambda_log_group.arn}:*"]
  }
}

resource "aws_iam_role_policy" "canary_lambda_cloudwatch_policy" {
  name   = "${local.function_name}-cloudwatch-policy"
  policy = "${data.aws_iam_policy_document.cloudwatch_role_policy_document.json}"
  role   = "${aws_iam_role.canary_lambda_role.id}"
}

# Permissions to publish messages via SNS
data "aws_iam_policy_document" "lambda_sns_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "canary_lambda_sns_policy" {
  name   = "${local.function_name}-sns-policy"
  policy = "${data.aws_iam_policy_document.lambda_sns_policy_document.json}"
  role   = "${aws_iam_role.canary_lambda_role.id}"
}

# Zip the python package for deployment
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "canary.zip"
}

resource "aws_lambda_function" "canary-lambda" {
  filename      = "canary.zip"
  function_name = "${local.function_name}"
  role          = "${aws_iam_role.canary_lambda_role.arn}"
  handler       = "canary.ping"

  source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"

  runtime = "python3.6"

  environment {
    variables = {
      TARGET_SITE         = "http://google.com"
      NOTIFICATION_NUMBER = "+xxxxxxxxx"
    }
  }
}

resource "null_resource" "lambda_build" {
  triggers {
    handler      = "${base64sha256(file("src/canary.py"))}"
    requirements = "${base64sha256(file("requirements.txt"))}"
    build        = "${base64sha256(file("src/build.sh"))}"
  }

  provisioner "local-exec" {
    working_dir = "${path.module}"
    command     = "src/build.sh"
  }
}
