output "table_name" {
  description = "Name of the table."
  value       = terraform_data.table.output.name
}

output "table_arn" {
  description = "ARN of the table."
  value       = terraform_data.table.output.arn
}

output "hash_key" {
  description = "Partition key of the table."
  value       = terraform_data.table.output.hash_key
}
