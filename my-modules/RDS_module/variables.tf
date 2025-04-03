variable "vpc_id" {}
variable "node_security_group" {}
variable "subnet_ids" {}
variable "rds_username" {
  description = "db username"
  type        = string
  sensitive   = true
}
variable "rds_password" {
  description = "db password"
  type        = string
  sensitive   = true
}
