# ---------------------------------------------------------------------------------------------------------------------
# A "VPC" - AWS-shaped on the outside, fake on the inside.
#
# Every resource below shows the real aws_* resource it stands in for, commented out, with a
# working stand-in underneath. That keeps the demo runnable with no AWS account and no
# credentials while the module's *interface* stays completely realistic - which is all that
# matters for demonstrating catalog and scaffold.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # One public and one private subnet per AZ - the usual layout.
  subnet_names = flatten([
    for az in var.azs : [
      "${var.name}-public-${az}",
      "${var.name}-private-${az}",
    ]
  ])
}

# resource "aws_vpc" "this" {
#   cidr_block = var.cidr_block
#   tags       = merge(var.tags, { Name = var.name })
# }
resource "random_id" "vpc" {
  byte_length = 8
}

resource "terraform_data" "vpc" {
  input = {
    id         = "vpc-${random_id.vpc.hex}"
    name       = var.name
    cidr_block = var.cidr_block
    tags       = merge(var.tags, { Name = var.name })
  }
}

# resource "aws_subnet" "this" {
#   for_each          = toset(local.subnet_names)
#   vpc_id            = aws_vpc.this.id
#   availability_zone = regex("[a-z]+-[a-z]+-[0-9][a-z]$", each.key)
#   tags              = merge(var.tags, { Name = each.key })
# }
resource "random_id" "subnet" {
  for_each    = toset(local.subnet_names)
  byte_length = 8
}

resource "terraform_data" "subnet" {
  for_each = toset(local.subnet_names)

  input = {
    id     = "subnet-${random_id.subnet[each.key].hex}"
    name   = each.key
    vpc_id = terraform_data.vpc.output.id
    tags   = merge(var.tags, { Name = each.key })
  }
}

# resource "aws_nat_gateway" "this" {
#   count         = var.enable_nat_gateway ? 1 : 0
#   subnet_id     = values(aws_subnet.this)[0].id
#   tags          = var.tags
# }
resource "terraform_data" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  input = {
    id     = "nat-${random_id.vpc.hex}"
    vpc_id = terraform_data.vpc.output.id
    tags   = var.tags
  }
}
