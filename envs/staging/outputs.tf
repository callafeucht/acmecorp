output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "api_url" {
  value = "https://api.staging.${var.root_domain}"
}

output "web_url" {
  value = "https://app.staging.${var.root_domain}"
}

output "staging_zone_name_servers" {
  value = aws_route53_zone.staging.name_servers
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_master_user_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ci_deploy_role_arn" {
  value = module.ci_deploy.role_arn
}
