variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to Postgres on 5432 (typically the ECS task SGs for api and worker)"
  type        = list(string)
}

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.small"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 50
}

variable "db_name" {
  type    = string
  default = "acmecorp"
}

variable "master_username" {
  type    = string
  default = "acmecorp_admin"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}
