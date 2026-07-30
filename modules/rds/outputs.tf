output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN holding the auto-generated master password (JSON with username/password fields)"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
