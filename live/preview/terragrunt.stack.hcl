# ---------------------------------------------------------------------------------------------------------------------
# A COMPLETE ENVIRONMENT, IN ONE FILE.
#
# `terragrunt stack generate` expands this into .terragrunt-stack/, one directory per unit, each
# with its own terragrunt.hcl and terragrunt.values.hcl. Nothing under .terragrunt-stack/ is
# checked in - this file is the whole source of truth.
#
# Want a second environment? Copy this file to a new directory and change the values. That is
# the entire diff.
# ---------------------------------------------------------------------------------------------------------------------

unit "network" {
  source = "../../units/network"
  path   = "network"

  values = {
    name       = "preview"
    cidr_block = "10.40.0.0/16"
    team       = "platform"
  }
}

unit "app" {
  source = "../../units/app-service"
  path   = "app"

  values = {
    service_name = "api"
    image        = "ghcr.io/acme/api:v1.4.2"
    team         = "platform"

    environment_variables = {
      LOG_LEVEL = "info"
    }
  }
}
