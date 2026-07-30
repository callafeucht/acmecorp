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

variable "domain_name" {
  description = "Root domain already registered/hosted in Route53, e.g. \"acmecorp.com\". ASSUMPTION: the hosted zone for this domain already exists in this AWS account."
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
