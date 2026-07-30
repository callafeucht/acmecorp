# Bootstrap: creates the S3 bucket + DynamoDB lock table used as the
# remote state backend for every env/ configuration.
#
# This is intentionally NOT part of envs/* — you can't use a remote
# backend to create the remote backend. Run this once, by hand, with
# local state, before anything else:
#
#   cd bootstrap
#   terraform init
#   terraform apply
#
# After that, the bucket/table names below are referenced (as literal
# strings) in each envs/<name>/backend.tf. This config is not expected
# to change often and does not need its own remote state.

terraform {
  required_version = "~> 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region for state resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state"
  type        = string
  default     = "acmecorp-terraform-state"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Safety net: prevents `terraform destroy` from deleting the bucket
  # that holds the state for every other environment.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name = "acmecorp-terraform-locks"

  # Opting for pay-as-you-go since there will not be steady/
  # sustained load against the table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.lock.name
}
