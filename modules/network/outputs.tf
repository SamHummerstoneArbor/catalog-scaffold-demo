output "vpc_id" {
  description = "ID of the VPC."
  value       = terraform_data.vpc.output.id
}

output "subnet_ids" {
  description = "IDs of every subnet created, in stable order."
  value       = [for name in sort(local.subnet_names) : terraform_data.subnet[name].output.id]
}

output "cidr_block" {
  description = "CIDR block of the VPC."
  value       = terraform_data.vpc.output.cidr_block
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway, or null when enable_nat_gateway is false."
  value       = var.enable_nat_gateway ? terraform_data.nat_gateway[0].output.id : null
}
