<!-- Frontmatter
name: App Service (ECS Fargate)
description: A containerised service on Fargate, with a log group, task definition and load balancer target group.
tags: [compute, aws, service, module]
-->

# App Service (ECS Fargate)

Runs a container as a long-lived service: cluster, log group, task definition, target group and
the service itself.

Four required inputs, eight optional ones. Reading all twelve out of `variables.tf` by hand,
along with their types and defaults, is exactly the job `terragrunt scaffold` removes.

This module **does** ship a `.boilerplate/` directory, so scaffolding it produces house style
rather than the built-in template's output: a wired-up `dependency` block on the network unit,
standard tags in `locals`, and a unit README. Compare it against `modules/network` (no template)
in Act 3 of the repo README.

## Usage

```hcl
terraform {
  source = "../../../modules/app-service"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  service_name = "api"
  image        = "ghcr.io/acme/api:v1.4.2"
  vpc_id       = dependency.network.outputs.vpc_id
  subnet_ids   = dependency.network.outputs.subnet_ids
}
```

## Note

The resources are `terraform_data` and `random_id` stand-ins - the commented-out `aws_*` blocks
in `main.tf` show what each represents. No AWS account is needed to run this.
