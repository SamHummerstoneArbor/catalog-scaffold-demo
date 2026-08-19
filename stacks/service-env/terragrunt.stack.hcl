# ---------------------------------------------------------------------------------------------------------------------
# A REUSABLE ENVIRONMENT.
#
# live/preview/terragrunt.stack.hcl hard-codes its values. This one takes them from `values`, so
# it can be stamped out for any environment:
#
#     mkdir -p live/qa && cd live/qa
#     terragrunt scaffold "$(git rev-parse --show-toplevel)//stacks/service-env"
#
# That copies this file and generates a terragrunt.values.hcl next to it, with the required
# values listed as TODO and the optional ones pre-filled from the try() fallbacks below.
#
# Convention: unit sources are relative to this file, and a stack instance is expected to live
# two directories below the repo root - live/<env>/ - which is the same depth as this directory.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Required: referenced directly, so scaffold lists them under "Required".
  env_name   = values.env_name
  cidr_block = values.cidr_block

  # Optional: wrapped in try(), so scaffold lists them under "Optional" with these defaults.
  team          = try(values.team, "unassigned")
  image         = try(values.image, "ghcr.io/acme/api:v1.4.2")
  desired_count = try(values.desired_count, 2)
}

unit "network" {
  source = "../../units/network"
  path   = "network"

  values = {
    name       = local.env_name
    cidr_block = local.cidr_block
    team       = local.team
  }
}

unit "app" {
  source = "../../units/app-service"
  path   = "app"

  values = {
    service_name  = "api"
    image         = local.image
    desired_count = local.desired_count
    team          = local.team

    environment_variables = {
      LOG_LEVEL = local.env_name == "prod" ? "warn" : "debug"
    }
  }
}
