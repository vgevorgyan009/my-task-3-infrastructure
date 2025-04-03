output "secrets_role_arn" {
  value = aws_iam_role.external_secrets_role.arn
}

output "dns_role_arn" {
  value = aws_iam_role.external_dns_role.arn
}
