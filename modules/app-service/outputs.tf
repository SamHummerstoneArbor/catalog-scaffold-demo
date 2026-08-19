output "service_arn" {
  description = "ARN of the ECS service."
  value       = terraform_data.service.output.arn
}

output "service_name" {
  description = "Name of the ECS service."
  value       = terraform_data.service.output.name
}

output "endpoint" {
  description = "URL the service is reachable on."
  value       = "https://${local.qualified_name}.example.internal:${var.container_port}"
}

output "log_group_name" {
  description = "Name of the log group container logs are written to."
  value       = terraform_data.log_group.output.name
}
