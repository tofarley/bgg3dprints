terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5.0"
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

resource "random_pet" "website_bucket_name" {
  prefix = "bgg3dprints-web"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

#.deploy/terraform/static-site/iam.tf
data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["*"]
      type = "*"
    }
    resources = [
      "${aws_s3_bucket.website_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.app_name}.${var.domain_name}"
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.website_policy.json
}

resource "aws_s3_bucket_website_configuration" "website_bucket_configuration" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "search/"
    }
    redirect {
      replace_key_prefix_with = "result/"
      host_name = "${aws_lambda_function_url.test_latest.url_id}.lambda-url.${var.aws_region}.on.aws"

      #host_name = <url_id>.lambda-url.<region>.on.aws
      #host_name = "iil7g7seqoihgoayfd5hr2pkx40ikost.lambda-url.us-east-1.on.aws"
      protocol = "https"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access_block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# [
#     {
#         "Condition": {
#             "KeyPrefixEquals": "search/"
#         },
#         "Redirect": {
#             "HostName": "iil7g7seqoihgayfd5hr2pkx40ikost.lambda-url.us-east-1.on.aws",
#             "Protocol": "https",
#             "ReplaceKeyPrefixWith": "result/"
#         }
#     }
# ]

resource "aws_s3_object" "object1" {
  for_each = fileset("dist/", "*")
  bucket = aws_s3_bucket.website_bucket.id
  key = each.value
  content_type = "text/html"
  source = "dist/${each.value}"
  #acl = "public-read"
  etag = filemd5("dist/${each.value}")
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

  compatible_runtimes = ["python3.10"]
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

  runtime = "python3.10"
  handler = "lambda_function.lambda_handler"
  timeout = 300
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

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.primary.zone_id
  name = var.app_name
  type = "A"
  alias {
    name = aws_s3_bucket_website_configuration.website_bucket_configuration.website_domain
    zone_id = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}