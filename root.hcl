# ---------------------------------------------------------------------------------------------------------------------
# ROOT TERRAGRUNT CONFIGURATION
#
# Every unit in live/ includes this file. It does three jobs:
#   1. Declares the module *catalog* that `terragrunt catalog` browses.
#   2. Configures state storage (local, so this demo needs no cloud account).
#   3. Holds the inputs shared by every unit, so the units themselves stay tiny.
# ---------------------------------------------------------------------------------------------------------------------

# `terragrunt catalog` walks up from wherever you run it looking for the root config file
# (it prefers root.hcl when one exists) and reads this block to decide what to show you.
catalog {
  urls = [
    # "." is this repo. Terragrunt rewrites a relative url to an absolute path, which is why
    # units scaffolded from a local catalog get an absolute `source`. See Act 1 in the README.
    ".",

    # ACT 6: comment out "." above, uncomment this, and the very same catalog is served from a
    # shared remote repo instead - this time with real `?ref=` version pinning.
    # "github.com/SamHummerstoneArbor/catalog-scaffold-demo",
  ]

  # ACT 3: uncomment this to give every module that does NOT ship its own .boilerplate/
  # directory a house-style scaffold template, without touching a single module.
  # default_template = "./templates/terragrunt-unit/.boilerplate"

  # Boilerplate templates can run shell commands and hooks. This repo's templates need neither,
  # so both are off - which is exactly what you want set before ever pointing a catalog at a
  # repo you don't control.
  no_shell = true
  no_hooks = true
}

locals {
  # Path of this unit relative to the repo root, e.g. "live/dev/network".
  unit_path  = path_relative_to_include()
  path_parts = split("/", local.unit_path)

  # Environment name = the directory directly under live/, e.g. "dev".
  env = length(local.path_parts) > 1 ? local.path_parts[1] : "sandbox"
}

# State lives in .terragrunt-state/ at the repo root - deliberately NOT inside the unit
# directory. Stack-generated units live under .terragrunt-stack/, which `terragrunt stack clean`
# deletes wholesale, so state anchored to the unit directory would be destroyed by a clean.
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    path = "${get_repo_root()}/.terragrunt-state/${local.unit_path}/terraform.tfstate"
  }
}

# Shared by every unit, so no unit has to repeat it.
inputs = {
  tags = {
    Environment = local.env
    ManagedBy   = "terragrunt"
    Repo        = "catalog-scaffold-demo"
  }
}
