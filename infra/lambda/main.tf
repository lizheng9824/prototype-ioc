provider "aws" {
  region = "ap-northeast-1"
  profile = "default"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.0.0"
    }
  }

  backend "s3" {
    bucket = "prototype-ioc-terraform"
    region = "ap-northeast-1"
    key = "terraform-lambda.tfstate"
    encrypt = true
  }
}

data "archive_file" "function_zip" {
  type = "zip"
  source_dir = "../../app/lambda"
  output_path = "../../build/function.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Sid": ""
    }      
  })
}

resource "aws_iam_role_policy" "lambda_access_policy" {
  name = "lambda_access_policy"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement" : [
          {
              "Effect": "Allow"
              "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
              ],
              "Resource": "arn:aws:logs:*:*:*"
          }
      ]
  })
}

resource "aws_lambda_function" "lambda_sample_function" {
  function_name = "lambda_sample"
  runtime = "python3.9"
  role = aws_iam_role.iam_for_lambda.arn
  filename = data.archive_file.function_zip.output_path
  handler = "lambda_sample.handler"
  source_code_hash = data.archive_file.function_zip.output_base64sha256

  environment {
    variables = {
      BASE_MESSAGE = "Hello"
    }
  }

#  depends_on = [aws_iam_role_policy_attachment.lambda_policy, aws_cloudwatch_log_group.lambda_log_group]
}