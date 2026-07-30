variable "name" {
  type = string
}

variable "github_repo" {
  description = "\"org/repo\" allowed to assume this role via OIDC"
  type        = string
}

variable "passable_role_arns" {
  description = "Task execution + task role ARNs this CI role is allowed to pass to ECS when registering task definitions"
  type        = list(string)
}
