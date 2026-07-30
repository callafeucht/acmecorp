# Bootstrap: management account. Creates the S3 bucket + DynamoDB lock
# table used as the remote state backend for every envs/<name>
# configuration, plus the "tf-exec" IAM role that is the human entry
# point for all day-to-day Terraform work in this repo.
#
# This is intentionally NOT part of envs/* — you can't use a remote
# backend to create the remote backend. Run this once, by hand, with
# local state, before anything else, using your real/root credentials
# in the management account:
#
#   cd bootstrap/management
#   terraform init
#   terraform apply
#
# After that, authenticate day-to-day as the "tf-exec" role this
# creates (e.g. via an AWS SSO profile or `aws sts assume-role`) —
# every envs/<name>/providers.tf assumes into that env's own account
# from there. The bucket/table names below are referenced (as literal
# strings) in each envs/<name>/backend.tf. This config is not expected
# to change often and does not need its own remote state.
#
# Chicken-and-egg note: bootstrap/production and bootstrap/staging each
# create a "tf-exec" role that trusts THIS account's tf-exec role
# (var.trusted_principal_arns below feeds the reverse direction — who's
# allowed to assume management's tf-exec in the first place). Since
# tf-exec doesn't exist yet in production/staging when this bootstrap
# runs, apply this one first, then apply those two using your AWS
# Organization's cross-account access (e.g. OrganizationAccountAccessRole),
# not tf-exec.

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

variable "trusted_principal_arns" {
  description = "IAM principal ARNs (SSO role, IAM users, etc.) allowed to assume the tf-exec role in this account — i.e. how the human engineers actually authenticate day-to-day."
  type        = list(string)
}

variable "production_account_id" {
  description = "AWS account ID of the production account."
  type        = string
}

variable "staging_account_id" {
  description = "AWS account ID of the staging account."
  type        = string
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

resource "aws_iam_role" "tf_exec" {
  name = "tf-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.trusted_principal_arns }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "tf_exec" {
  name = "tf-exec"
  role = aws_iam_role.tf_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeChildAccountRoles"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${var.production_account_id}:role/tf-exec",
          "arn:aws:iam::${var.staging_account_id}:role/tf-exec",
        ]
      },
      {
        # Required because envs/<name>'s S3 backend authenticates as
        # this role directly (backend.tf has no assume_role of its own)
        # — see the note in envs/prod/providers.tf.
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
        ]
      },
      {
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = aws_dynamodb_table.lock.arn
      }
    ]
  })
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.lock.name
}

output "tf_exec_role_arn" {
  value = aws_iam_role.tf_exec.arn
}
