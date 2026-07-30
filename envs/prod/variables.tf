variable "region" {
  type    = string
  default = "us-east-1"
}

variable "root_domain" {
  description = "Root domain, already hosted in Route53. ASSUMPTION - see README."
  type        = string
  default     = "acmecorp.com"
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
