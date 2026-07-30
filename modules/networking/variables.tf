variable "name" {
  description = "Name prefix for networking resources, e.g. \"acme-staging\""
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Required, no default - every environment must pick its own non-overlapping range (see README)."
  type        = string
}

variable "az_count" {
  description = "Number of AZs to spread public/private subnets across"
  type        = number
  default     = 2
}
