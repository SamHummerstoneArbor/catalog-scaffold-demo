<!-- Frontmatter
name: Data Store (DynamoDB)
description: A key-value table with optional sort key, point-in-time recovery and TTL.
tags: [database, aws, storage]
-->

# Data Store (DynamoDB)

A single table with a partition key, an optional sort key, and optional point-in-time recovery
and TTL.

Like `modules/network`, this module ships **no** `.boilerplate/` directory. That makes the pair
of them the proof for Act 3: uncomment one line in `root.hcl` and both start scaffolding in
house style, without either module changing.

## Usage

```hcl
terraform {
  source = "../../../modules/data-store"
}

inputs = {
  table_name = "sessions"
  hash_key   = "session_id"
}
```

## Note

The table is a `terraform_data` stand-in - the commented-out `aws_dynamodb_table` block in
`main.tf` shows what it represents. No AWS account is needed.
