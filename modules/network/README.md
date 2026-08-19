<!-- Frontmatter
name: Network (VPC)
description: A VPC with public and private subnets across the given availability zones, and an optional NAT gateway.
tags: [networking, aws, foundation]
-->

# Network (VPC)

Creates the network foundation everything else sits on: a VPC, one public and one private
subnet per availability zone, and optionally a NAT gateway.

This module ships **no** `.boilerplate/` directory, so `terragrunt scaffold` falls back to
Terragrunt's built-in template. That makes it the baseline to compare the other two template
tiers against - see Act 3 in the repo README.

## Usage

```hcl
terraform {
  source = "../../modules/network"
}

inputs = {
  name       = "dev"
  cidr_block = "10.0.0.0/16"
}
```

## Note

The resources here are `terraform_data` and `random_id` stand-ins, not real AWS resources - the
commented-out `aws_*` blocks in `main.tf` show what each one represents. The module interface is
real; only the cloud calls are missing, so the whole demo runs with no AWS account.
