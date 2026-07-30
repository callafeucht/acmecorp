# Bootstrap: staging account. Creates this account's "tf-exec" IAM
# role (trusted by management's tf-exec role — see
# bootstrap/management/main.tf) and the GitHub OIDC provider that
# modules/ci_deploy assumes already exists.
#
# Run once, by hand, with local state, using your AWS Organization's
# cross-account access into this account (e.g. OrganizationAccountAccessRole)
# — NOT tf-exec, which doesn't exist yet in this account until this
# config creates it:
#
#   cd bootstrap/staging
#   terraform init
#   terraform apply
#
# After this applies, envs/staging's provider assumes into the
# tf_exec_role_arn this outputs.

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
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "management_tf_exec_role_arn" {
  description = "ARN of the tf-exec role in the management account (output of bootstrap/management) — the only principal allowed to assume this account's tf-exec role."
  type        = string
}

resource "aws_iam_role" "tf_exec" {
  name = "tf-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.management_tf_exec_role_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

# v1 simplicity tradeoff: broad admin access for the Terraform exec
# role, same "operational simplicity first" tradeoff already made
# elsewhere in this repo (see modules/networking/main.tf's single-NAT
# comment). Scoping this down to exactly what envs/staging's modules
# actually provision is real follow-up work, not an oversight.
resource "aws_iam_role_policy_attachment" "tf_exec_admin" {
  role       = aws_iam_role.tf_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ASSUMPTION: CI is GitHub Actions. Created here (an account-level
# resource) rather than as a `data` lookup inside modules/ci_deploy,
# since nothing pre-exists in a freshly split account.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

output "tf_exec_role_arn" {
  value = aws_iam_role.tf_exec.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
