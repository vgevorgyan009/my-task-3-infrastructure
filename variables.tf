variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
variable "region" {}
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}
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
