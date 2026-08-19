# A reusable, parameterised unit.
#
# The units in live/dev/ hard-code their values. This one hard-codes nothing: everything comes
# from `values`, which a terragrunt.stack.hcl supplies when it instantiates the unit. That is
# what lets one stack file stamp out the same unit across as many environments as you like.
terraform {
  source = "${get_repo_root()}//modules/network"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = {
  # Referenced directly, so the stack MUST supply them. `terragrunt scaffold` reads this and
  # lists them under "Required" in the terragrunt.values.hcl it generates.
  name       = values.name
  cidr_block = values.cidr_block

  # Wrapped in try(), so the stack MAY supply them. These come out under "Optional", with the
  # fallback pre-filled.
  azs                = try(values.azs, ["eu-west-2a", "eu-west-2b"])
  enable_nat_gateway = try(values.enable_nat_gateway, false)

  tags = merge(include.root.inputs.tags, {
    Owner = try(values.team, "unassigned")
  })
}
