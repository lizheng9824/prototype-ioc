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
    key = "terraform-api-gateway.tfstate"
    encrypt = true
  }
}

resource "aws_iam_role" "apigateway_putlog" {
  name = "apigateway_putlog"

  assume_role_policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_putlog" {
  role       = "${aws_iam_role.apigateway_putlog.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "my_api" {
  cloudwatch_role_arn = aws_iam_role.apigateway_putlog.arn
}


resource "aws_api_gateway_rest_api" "helloworld" {
  name = "api_gateway_rest_api"
}

resource "aws_api_gateway_resource" "helloworld" {
  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  parent_id = aws_api_gateway_rest_api.helloworld.root_resource_id

  path_part = "helloworld"
}

resource "aws_api_gateway_method" "helloworld" {
  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  resource_id = aws_api_gateway_resource.helloworld.id

  http_method = "GET"
  authorization = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.querystring.last_name": true,
    "method.request.querystring.first_name": true
  }
}


resource "aws_api_gateway_method_response" "helloworld" {
  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  resource_id = aws_api_gateway_resource.helloworld.id
  http_method = aws_api_gateway_method.helloworld.http_method

  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

module "lambda" {
  source = "../lambda"
  
}

resource "aws_api_gateway_integration" "helloworld" {

  # source = "../lambda"

  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  resource_id = aws_api_gateway_resource.helloworld.id
  http_method = aws_api_gateway_method.helloworld.http_method
  
  integration_http_method = "POST"
  type = "AWS_PROXY"

  uri = module.lambda.aws_lambda_function_helloworld.invoke_arn
}

resource "aws_api_gateway_deployment" "helloworld" {
  rest_api_id = aws_api_gateway_rest_api.helloworld.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.helloworld.id,
      aws_api_gateway_method.helloworld.id,
      aws_api_gateway_integration.helloworld.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "helloworld" {
  deployment_id = aws_api_gateway_deployment.helloworld.id
  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  stage_name = "helloworldapi"
}


resource "aws_api_gateway_method_settings" "all" {
  depends_on = [
    aws_api_gateway_account.my_api,
  ]

  rest_api_id = aws_api_gateway_rest_api.helloworld.id
  stage_name  = aws_api_gateway_stage.helloworld.stage_name
  method_path = "*/*"

  settings {
    logging_level = "ERROR"
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.helloworld.execution_arn}/*/${aws_api_gateway_method.helloworld.http_method}/${aws_api_gateway_resource.helloworld.path_part}"
 }