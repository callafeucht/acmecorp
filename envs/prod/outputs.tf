output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "api_url" {
  value = "https://api.${var.root_domain}"
}

output "web_url" {
  value = "https://app.${var.root_domain}"
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
