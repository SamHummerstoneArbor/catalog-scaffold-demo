<!-- Frontmatter
name: Network unit
description: A parameterised network unit, driven entirely by stack values. The building block a service environment stack instantiates.
tags: [networking, unit]
-->

# Network unit

A ready-made Terragrunt unit for `modules/network`, parameterised by `values` rather than
hard-coded inputs.

Scaffolding this **copies** it rather than generating it, and derives a
`terragrunt.values.hcl` from how it uses `values.*`:

- `values.name` and `values.cidr_block` are referenced directly, so they land under **Required**
- `values.azs`, `values.enable_nat_gateway` and `values.team` are wrapped in `try()`, so they
  land under **Optional** with their fallbacks pre-filled
