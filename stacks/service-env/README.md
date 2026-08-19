<!-- Frontmatter
name: Service environment
description: A complete environment - network plus app service, fully wired - stamped out from a handful of values.
tags: [environment, stack]
-->

# Service environment

A whole environment in one file: a network unit and an app-service unit, with the dependency
between them already wired.

Scaffold it into a new environment directory and Terragrunt writes a `terragrunt.values.hcl`
alongside it listing exactly what you have to fill in:

```bash
mkdir -p live/qa && cd live/qa
terragrunt scaffold "$(git rev-parse --show-toplevel)//stacks/service-env"
# fill in env_name and cidr_block in terragrunt.values.hcl
terragrunt stack generate
terragrunt stack run apply
```

Two values is the entire cost of a new environment.
