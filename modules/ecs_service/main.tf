# ecs_service module: a single Fargate task definition + service.
# Reused 3x per environment (api, web, worker) with different images,
# ports, and ALB wiring - this is the module that keeps main.tf DRY.
#
# - api / web: pass alb_target_group_arn + container_port, gets a security
#   group rule allowing ingress from the ALB.
# - worker: leave alb_target_group_arn = null and container_port = null.
#   No ingress rule is created; it only needs egress (to Postgres and the
#   SMS/email provider).

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_security_group" "service" {
  name        = "${var.name}-svc"
  description = "Security group for ${var.name} ECS service"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-svc-sg"
  }
}

resource "aws_security_group_rule" "from_alb" {
  count = var.alb_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.service.id
  source_security_group_id = var.alb_security_group_id
}

# --- IAM ---
# Execution role: pulls the image from ECR and ships logs to CloudWatch.
# Also gets read access to whichever secrets this service was told about.
resource "aws_iam_role" "execution" {
  name = "${var.name}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${var.name}-secrets-access"
  role  = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [for s in var.secrets : s.value_from]
    }]
  })
}

# Task role: what the application itself is allowed to do at runtime.
# Kept empty by default - pass task_role_policy_json for anything a
# specific service needs beyond the basics (e.g. worker calling out to
# the SMS/email provider doesn't need AWS permissions for that, but a
# future service that writes to S3 would get its policy here).
resource "aws_iam_role" "task" {
  name = "${var.name}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "task_extra" {
  count  = var.task_role_policy_json != null ? 1 : 0
  name   = "${var.name}-task-extra"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}

# --- Task definition + service ---
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true
      portMappings = var.container_port != null ? [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ] : []
      environment = [for k, v in var.environment : { name = k, value = v }]
      secrets     = [for k, s in var.secrets : { name = k, valueFrom = s.value_from }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = var.name
      container_port   = var.container_port
    }
  }

  # Give the ALB time to deregister old tasks before new ones are killed
  # isn't needed here - Fargate handles this via deployment config below.
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
}
