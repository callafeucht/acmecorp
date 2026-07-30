output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arns" {
  description = "Map of service name -> target group ARN"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}
