variable "region" {
  type    = string
  default = "us-east-1"
}

variable "root_domain" {
  description = "Root domain. This config creates and owns the Route53 zone for it (aws_route53_zone.root) - see README."
  type        = string
  default     = "acmecorp.com"
}

variable "tf_exec_role_arn" {
  description = "ARN of this account's tf-exec role, created by bootstrap/production."
  type        = string
}

variable "staging_zone_name_servers" {
  description = "Name servers of staging's Route53 zone, from `terraform output staging_zone_name_servers` in envs/staging. Used to create the NS delegation record in this account's root zone - see README."
  type        = list(string)
}

variable "github_repo" {
  description = "\"org/repo\" allowed to deploy via CI (org/acme-corp style)"
  type        = string
}

variable "api_image_tag" {
  type    = string
  default = "latest"
}

variable "web_image_tag" {
  type    = string
  default = "latest"
}

variable "worker_image_tag" {
  type    = string
  default = "latest"
}

variable "sms_email_provider_secret_arn" {
  description = "Secrets Manager ARN for the third-party SMS/email provider API key. Created once by hand (or in a separate secrets.tf) and referenced here - see README."
  type        = string
}
