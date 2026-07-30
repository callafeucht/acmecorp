locals {
  name     = "acme-staging"
  vpc_cidr = "10.0.0.0/16"
}

module "networking" {
  source   = "../../modules/networking"
  name     = local.name
  vpc_cidr = local.vpc_cidr
}

module "ecr" {
  source     = "../../modules/ecr"
  name       = local.name
  repo_names = ["api", "web", "worker"]
}

# Single-use resource (one cluster per env) - not worth a module on its own.
resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_route53_zone" "staging" {
  name = "staging.${var.root_domain}"
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  route53_zone_id   = aws_route53_zone.staging.zone_id

  services = [
    {
      name              = "api"
      host_header       = "api.staging.${var.root_domain}"
      port              = 8080
      health_check_path = "/healthz"
    },
    {
      name              = "web"
      host_header       = "app.staging.${var.root_domain}"
      port              = 3000
      health_check_path = "/"
    },
  ]
}

module "rds" {
  source              = "../../modules/rds"
  name                = local.name
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  instance_class      = "db.t4g.micro"
  allocated_storage   = 20
  multi_az            = false
  deletion_protection = false # staging only

  allowed_security_group_ids = [
    module.ecs_api.security_group_id,
    module.ecs_worker.security_group_id,
  ]
}

module "ecs_api" {
  source         = "../../modules/ecs_service"
  name           = "${local.name}-api"
  region         = var.region
  cluster_id     = aws_ecs_cluster.this.id
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  image          = "${module.ecr.repository_urls["api"]}:${var.api_image_tag}"
  container_port = 8080
  cpu            = 256
  memory         = 512
  desired_count  = 1

  alb_target_group_arn  = module.alb.target_group_arns["api"]
  alb_security_group_id = module.alb.alb_security_group_id

  environment = {
    ENVIRONMENT = "staging"
    DB_HOST     = module.rds.db_endpoint
    DB_NAME     = "acmecorp"
  }

  secrets = {
    DB_CREDENTIALS = { value_from = module.rds.master_user_secret_arn }
  }
}

module "ecs_web" {
  source         = "../../modules/ecs_service"
  name           = "${local.name}-web"
  region         = var.region
  cluster_id     = aws_ecs_cluster.this.id
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  image          = "${module.ecr.repository_urls["web"]}:${var.web_image_tag}"
  container_port = 3000
  cpu            = 256
  memory         = 512
  desired_count  = 1

  alb_target_group_arn  = module.alb.target_group_arns["web"]
  alb_security_group_id = module.alb.alb_security_group_id

  environment = {
    ENVIRONMENT  = "staging"
    API_BASE_URL = "https://api.staging.${var.root_domain}"
  }
}

module "ecs_worker" {
  source        = "../../modules/ecs_service"
  name          = "${local.name}-worker"
  region        = var.region
  cluster_id    = aws_ecs_cluster.this.id
  vpc_id        = module.networking.vpc_id
  subnet_ids    = module.networking.private_subnet_ids
  image         = "${module.ecr.repository_urls["worker"]}:${var.worker_image_tag}"
  cpu           = 256
  memory        = 512
  desired_count = 1
  # No container_port, no alb_target_group_arn/alb_security_group_id -
  # worker isn't behind the ALB, it just polls/reacts to schedule.

  environment = {
    ENVIRONMENT = "staging"
    DB_HOST     = module.rds.db_endpoint
    DB_NAME     = "acmecorp"
  }

  secrets = {
    DB_CREDENTIALS         = { value_from = module.rds.master_user_secret_arn }
    SMS_EMAIL_PROVIDER_KEY = { value_from = var.sms_email_provider_secret_arn }
  }
}

module "ci_deploy" {
  source      = "../../modules/ci_deploy"
  name        = local.name
  github_repo = var.github_repo

  passable_role_arns = [
    module.ecs_api.execution_role_arn,
    module.ecs_api.task_role_arn,
    module.ecs_web.execution_role_arn,
    module.ecs_web.task_role_arn,
    module.ecs_worker.execution_role_arn,
    module.ecs_worker.task_role_arn,
  ]
}
