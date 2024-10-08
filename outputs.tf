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

output "website_endpoint" {
  description = "URL of the website"

  value = "http://${aws_s3_bucket_website_configuration.website_bucket_configuration.website_endpoint}"
}

output "website_url" {
  description = "Application URL"

  value = "http://${var.app_name}.${var.domain_name}"
}

output "zone_name_servers" {
  value       = aws_route53_zone.primary.name_servers
  description = "Name servers for the Route53 zone"
}