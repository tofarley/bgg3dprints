# BGG 3D Prints

## About

This repository contains links to 3D printable files for various board game accessories and components. These designs are intended to enhance your gaming experience by providing custom storage solutions, game piece upgrades, and other useful additions to your favorite board games.

## Usage

This repository can be deployed to AWS as a lambda function using terraform.

1. Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli (This guide was written for Terraform v1.9.5)

2. Install git: https://github.com/git-guides/install-git (This guide was written for git version 2.25.1)

3. Clone this repository: `git clone https://github.com/tofarley/bgg3dprints.git`

4. Modify the `terraform.tfvars` file to point to a domain that you own.

```
aws_region = "us-east-1"
domain_name = "imagitronics.org"
app_name = "bgg3dprints"
```

In the example above, you would need to own the imagitronics.org domain, and the app would be hosted at bgg3dprints.imagitronics.org.


5. Run all the things.


```terraform init```

```terraform plan```

```terraform apply```

# Update your DNS

You would now need to update your DNS records. For example:

```
function_name = "bgg3dprints"
function_url = "https://t7dl7dijy6jp4bx54ed5p6l7e40kswvg.lambda-url.us-east-1.on.aws/"
lambda_bucket_name = "bgg3dprints-mutually-brightly-pretty-wahoo"
website_endpoint = "http://bgg3dprints.imagitronics.org.s3-website-us-east-1.amazonaws.com"
website_url = "http://bgg3dprints.imagitronics.org"
zone_name_servers = tolist([
  "ns-1131.awsdns-13.org",
  "ns-1873.awsdns-42.co.uk",
  "ns-352.awsdns-44.com",
  "ns-943.awsdns-53.net",
])
```

I purchased my DNS through hover.com, so I would need to login to hover.com and update the nameservers for my domain to match the ones reported above... You will need to do this with whatever company you used to buy your domain name.

## Contact

For questions, suggestions, or issues related to these 3D printable files, please open an issue in this repository or contact the repository owner directly.

Happy printing and gaming!

# References

https://developer.hashicorp.com/terraform/tutorials/aws/lambda-api-gateway) tutorial

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions

https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config

https://medium.com/egen/automating-aws-lambda-layer-creation-for-python-with-makefile-cde085ef61e2

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html

https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

# Local testing lambda

```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"queryStringParameters": {"username": "tofarley"}}'
```
