# ---------------------------------------------------------------------------------------------------------------------
# A "DynamoDB table" - AWS-shaped on the outside, fake on the inside.
# ---------------------------------------------------------------------------------------------------------------------

resource "random_id" "table" {
  byte_length = 4
}

# resource "aws_dynamodb_table" "this" {
#   name         = var.table_name
#   billing_mode = var.billing_mode
#   hash_key     = var.hash_key
#   range_key    = var.range_key
#
#   point_in_time_recovery { enabled = var.point_in_time_recovery }
#
#   dynamic "ttl" {
#     for_each = var.ttl_attribute == null ? [] : [var.ttl_attribute]
#     content {
#       attribute_name = ttl.value
#       enabled        = true
#     }
#   }
#
#   tags = var.tags
# }
resource "terraform_data" "table" {
  input = {
    name                   = var.table_name
    arn                    = "arn:aws:dynamodb:eu-west-2:000000000000:table/${var.table_name}-${random_id.table.hex}"
    billing_mode           = var.billing_mode
    hash_key               = var.hash_key
    range_key              = var.range_key
    point_in_time_recovery = var.point_in_time_recovery
    ttl_attribute          = var.ttl_attribute
    tags                   = var.tags
  }
}
