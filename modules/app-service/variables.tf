# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "Name of the service. Used for the task definition, log group and load balancer target group."
  type        = string
}

variable "image" {
  description = "Container image to run, including tag, e.g. ghcr.io/acme/api:v1.4.2."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to run the service in. Usually wired to the network module's vpc_id output."
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets to place tasks in. Usually wired to the network module's subnet_ids output."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# There are deliberately a lot of these. Reading them all out of this file by hand is exactly
# the job that `terragrunt scaffold` does for you.
# ---------------------------------------------------------------------------------------------------------------------

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units to reserve per task. 1024 units is one vCPU."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MiB to reserve per task."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path the load balancer polls to decide whether a task is healthy."
  type        = string
  default     = "/healthz"
}

variable "environment_variables" {
  description = "Environment variables to pass to the container."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "How long to keep container logs for."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
