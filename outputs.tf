# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.bgg3dprints.function_name
}

output "function_url" {
  description = "URL of the function"

  value = aws_lambda_function_url.test_latest.function_url
}