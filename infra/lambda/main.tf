variable "user_pool_name" {}
variable "env" {}
variable "system_name" {
  default="terraform-lambda-deployment"
}

data "archive_file" "layer_zip" {
    type = "zip"
    source_dir = "build/layer"
    output_path = "lambda/layer.zip"
}

data "archive_file" "function_zip" {
  type = "zip"
  source_dir = "build/function"
  output_path = "lambda/function.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "${system_name}_lambda_layer"
  filename = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.user_pool_name}-${var.env}"
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
  name = "${var.system_name}_lambda_access_policy"
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

resource "aws_lambda_function" "get_unixtime" {
  handler = "get_unixtime.lambda_handler"
  filename = data.archive_file.function_zip.output_path
  runtime = "python3.9"
  role = aws_iam_role.iam_for_lambda.arn
  function_name = "${system_name}-get_unixtime"

  source_code_hash = data.archive_file.function_zip.output_base64sha256
  layers = [aws_lambda_layer_version.lambda_layer.arn]

}