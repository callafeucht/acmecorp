variable "name" {
  description = "Name prefix, e.g. \"acme-staging\""
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "route53_zone_id" {
  description = "Zone ID of the Route53 hosted zone that owns var.services' host_header records. Caller creates/owns this zone; the module only writes records into it."
  type        = string
}

variable "services" {
  description = "Services to route to via host header. One target group + listener rule per entry."
  type = list(object({
    name              = string # e.g. "api", "web"
    host_header       = string # e.g. "api.acmecorp.com"
    port              = number # container port the service listens on
    health_check_path = string
  }))
}
