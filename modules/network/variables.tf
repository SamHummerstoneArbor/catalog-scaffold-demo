# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# No default, so `terragrunt scaffold` emits these as `name = "" # TODO: fill in value`.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name of the VPC. Every resource in this module is named after it."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC, e.g. 10.0.0.0/16."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# These have defaults, so `terragrunt scaffold` emits them commented out, with the default shown.
# ---------------------------------------------------------------------------------------------------------------------

variable "azs" {
  description = "Availability zones to spread subnets across. One public and one private subnet is created per AZ."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway so private subnets can reach the internet."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
