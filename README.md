# Learn Terraform - Lambda functions and API Gateway

AWS Lambda functions and API gateway are often used to create serverless
applications.

This repo is a companion repo to the [AWS Lambda functions and API gateway](https://developer.hashicorp.com/terraform/tutorials/aws/lambda-api-gateway) tutorial.

# Install
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions

https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config

https://medium.com/egen/automating-aws-lambda-layer-creation-for-python-with-makefile-cde085ef61e2

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html

https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

```terraform plan```

```terraform apply```

aws s3 sync dist/index.html s3://bgg3dprints-web-barely-merely-central-quagga/index.html

aws s3 sync dist/result.html s3://bgg3dprints-web-barely-merely-central-quagga/result.html



# .deploy/terraform/static-site/route53.tf
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.primary.zone_id
  name = var.app_name
  type = "A"
  alias {
    name = aws_s3_bucket.website_bucket.website_domain
    zone_id = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = false
  }
}

module "website" {
  source = "./deploy/terraform"
}



curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"queryStringParameters": {"username": "tofarley"}}'