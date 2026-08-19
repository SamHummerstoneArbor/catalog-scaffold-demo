# A reusable, parameterised app-service unit. See units/network for how `values` works.
terraform {
  source = "${get_repo_root()}//modules/app-service"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Plain dependency block. Inside a generated stack this resolves to the sibling unit that the
# stack placed at path = "network", so the wiring works without the stack file mentioning it.
dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id     = "vpc-mock"
    subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
}

inputs = {
  # Required - referenced directly.
  service_name = values.service_name
  image        = values.image

  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.subnet_ids

  # Optional - wrapped in try().
  desired_count         = try(values.desired_count, 2)
  environment_variables = try(values.environment_variables, {})

  tags = merge(include.root.inputs.tags, {
    Owner = try(values.team, "unassigned")
  })
}
