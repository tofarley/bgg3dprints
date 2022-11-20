# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type = string
}

variable "app_name" {
  type = string
  default = "bgg3dprints"
}