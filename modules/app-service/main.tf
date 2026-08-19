# ---------------------------------------------------------------------------------------------------------------------
# An "ECS Fargate service" - AWS-shaped on the outside, fake on the inside.
#
# Each real aws_* resource is shown commented out, with a working stand-in underneath, so the
# module's interface is realistic while the demo still runs with no AWS account.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  qualified_name = "${var.service_name}-${terraform_data.cluster.output.suffix}"
}

resource "random_id" "cluster" {
  byte_length = 4
}

# resource "aws_ecs_cluster" "this" {
#   name = var.service_name
#   tags = var.tags
# }
resource "terraform_data" "cluster" {
  input = {
    suffix = random_id.cluster.hex
    name   = var.service_name
    tags   = var.tags
  }
}

# resource "aws_cloudwatch_log_group" "this" {
#   name              = "/ecs/${var.service_name}"
#   retention_in_days = var.log_retention_days
#   tags              = var.tags
# }
resource "terraform_data" "log_group" {
  input = {
    name              = "/ecs/${var.service_name}"
    retention_in_days = var.log_retention_days
    tags              = var.tags
  }
}

# resource "aws_ecs_task_definition" "this" {
#   family                   = var.service_name
#   cpu                      = var.cpu
#   memory                   = var.memory
#   requires_compatibilities = ["FARGATE"]
#   container_definitions    = jsonencode([{ ... }])
# }
resource "terraform_data" "task_definition" {
  input = {
    family         = var.service_name
    cpu            = var.cpu
    memory         = var.memory
    image          = var.image
    container_port = var.container_port
    environment    = var.environment_variables
    log_group      = terraform_data.log_group.output.name
  }
}

# resource "aws_lb_target_group" "this" {
#   port     = var.container_port
#   vpc_id   = var.vpc_id
#   health_check { path = var.health_check_path }
# }
resource "terraform_data" "target_group" {
  input = {
    name              = local.qualified_name
    port              = var.container_port
    vpc_id            = var.vpc_id
    health_check_path = var.health_check_path
  }
}

# resource "aws_ecs_service" "this" {
#   name            = var.service_name
#   cluster         = aws_ecs_cluster.this.id
#   task_definition = aws_ecs_task_definition.this.arn
#   desired_count   = var.desired_count
#   network_configuration { subnets = var.subnet_ids }
# }
resource "terraform_data" "service" {
  input = {
    name            = var.service_name
    arn             = "arn:aws:ecs:eu-west-2:000000000000:service/${local.qualified_name}"
    desired_count   = var.desired_count
    subnet_ids      = var.subnet_ids
    task_definition = terraform_data.task_definition.output.family
    target_group    = terraform_data.target_group.output.name
  }
}
