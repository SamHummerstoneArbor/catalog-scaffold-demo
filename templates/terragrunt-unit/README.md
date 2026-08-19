<!-- Frontmatter
name: House unit template
description: The organisation-wide scaffold template, applied to any module that does not ship its own .boilerplate directory.
tags: [template, house-style]
-->

# House unit template

The organisation default scaffold template, wired up by `default_template` in `root.hcl`.

Any module without its own `.boilerplate/` directory scaffolds through this file, so the
conventions here - including the root config, exposing it, and merging rather than replacing the
shared tags - apply everywhere at once. Change this file and every such module changes with it.

The template itself lives in `.boilerplate/` rather than at the top level of this directory, so
that the `terragrunt.hcl` inside it is never mistaken for a real unit by `terragrunt run --all`.

Template resolution order, highest priority first:

1. a template passed as the second argument to `terragrunt scaffold`
2. the module's own `.boilerplate/` directory
3. `catalog.default_template` - this template
4. Terragrunt's built-in template
