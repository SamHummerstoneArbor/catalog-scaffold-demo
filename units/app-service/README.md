<!-- Frontmatter
name: App service unit
description: A parameterised app-service unit with the network dependency already wired. Driven entirely by stack values.
tags: [compute, unit]
-->

# App service unit

A ready-made Terragrunt unit for `modules/app-service`, parameterised by `values`, with the
`dependency` block on the sibling network unit already written.

Scaffolding this copies it and derives a `terragrunt.values.hcl`: `service_name` and `image`
under **Required**, `desired_count`, `environment_variables` and `team` under **Optional**.
