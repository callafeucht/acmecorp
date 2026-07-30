variable "name" {
  description = "Service name, e.g. \"acme-staging-api\""
  type        = string
}

variable "region" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets the tasks run in"
  type        = list(string)
}

variable "image" {
  description = "Full image URI including tag, e.g. <ecr-url>:latest"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on. Set to null for services not exposed via ALB (e.g. worker)."
  type        = number
  default     = null
}

variable "cpu" {
  description = "Fargate task CPU units (256 = .25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "environment" {
  description = "Plaintext env vars for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets injected as env vars. Map of env var name -> { value_from = secretsmanager ARN or ARN:jsonkey }"
  type = map(object({
    value_from = string
  }))
  default = {}
}

variable "alb_target_group_arn" {
  description = "Target group to register with, or null if this service isn't behind the ALB"
  type        = string
  default     = null
}

variable "alb_security_group_id" {
  description = "ALB's security group, used to allow ingress on container_port. Leave null if not behind the ALB."
  type        = string
  default     = null
}

variable "task_role_policy_json" {
  description = "Optional extra IAM policy (JSON) granted to the task role for app-level AWS permissions"
  type        = string
  default     = null
}

variable "log_retention_days" {
  type    = number
  default = 30
}
