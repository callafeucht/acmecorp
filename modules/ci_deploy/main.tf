# ci_deploy module: an IAM role that GitHub Actions can assume via OIDC
# (no long-lived AWS keys stored in CI) to push images to ECR and update
# ECS services. This is the direct replacement for "deploys are done by
# SSHing in."
#
# ASSUMPTION: CI is GitHub Actions and the repo is github.com/<org>/<repo>.
# If Acme Corp uses something else (GitLab, CircleCI, Buildkite), swap
# the OIDC provider and trust policy condition accordingly - the ECS/ECR
# permissions below stay the same.

data "aws_iam_openid_connect_provider" "github" {
  # ASSUMPTION: the GitHub OIDC provider already exists in this account
  # (either created once by hand or in a separate one-time bootstrap,
  # since it's an account-level resource shared across all repos/envs).
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "deploy" {
  name = "${var.name}-ci-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "${var.name}-ci-deploy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSDeploy"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRolesToECS"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = var.passable_role_arns
      }
    ]
  })
}
