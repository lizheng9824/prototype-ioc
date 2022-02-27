output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.helloworld.function_name
}

output "aws_lambda_function_helloworld" {
  value = aws_lambda_function.helloworld
}