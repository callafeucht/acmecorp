variable "name" {
  description = "Name prefix for repositories, e.g. \"acme-staging\""
  type        = string
}

variable "repo_names" {
  description = "List of service names to create ECR repos for, e.g. [\"api\", \"web\", \"worker\"]"
  type        = list(string)
}
