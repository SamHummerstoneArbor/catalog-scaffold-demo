# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "table_name" {
  description = "Name of the table."
  type        = string
}

variable "hash_key" {
  description = "Attribute to use as the partition key."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "range_key" {
  description = "Attribute to use as the sort key. Leave null for a partition-key-only table."
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "Billing mode. One of PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "point_in_time_recovery" {
  description = "Whether to enable continuous backups with point-in-time recovery."
  type        = bool
  default     = false
}

variable "ttl_attribute" {
  description = "Attribute holding an expiry timestamp. Leave null to disable TTL."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
