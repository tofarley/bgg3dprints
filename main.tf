terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "bgg3dprints"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

# Upload zip to S3
data "archive_file" "bgg3dprints" {
  type = "zip"

  source_dir  = "${path.module}/app"
  output_path = "${path.module}/app.zip"
}

data "archive_file" "bgg3dprints_layer" {
  type = "zip"

  source_dir  = "${path.module}/bgg3dprints-layer"
  output_path = "${path.module}/bgg3dprints-layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "${path.module}/bgg3dprints-layer.zip"
  layer_name = "bgg3dprints_layer"

  compatible_runtimes = ["python3.7"]
}

resource "aws_s3_object" "bgg3dprints" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "app.zip"
  source = data.archive_file.bgg3dprints.output_path

  etag = filemd5(data.archive_file.bgg3dprints.output_path)
}

# Create Lamdba function
resource "aws_lambda_function" "bgg3dprints" {
  function_name = "bgg3dprints"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.bgg3dprints.key

  runtime = "python3.7"
  handler = "lambda_function.lambda_handler"
  timeout = 10
  source_code_hash = data.archive_file.bgg3dprints.output_base64sha256
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "bgg3dprints" {
  name = "/aws/lambda/${aws_lambda_function.bgg3dprints.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.bgg3dprints.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

