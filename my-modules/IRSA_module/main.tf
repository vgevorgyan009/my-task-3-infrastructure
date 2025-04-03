resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "ClusterAutoscalerPolicy"
  path        = "/"
  description = "Custom IAM policy for Cluster Autoscaler"
  policy      = file("${path.module}/autoscalerpolicy.json")
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = var.eks_worker_role_name
}

resource "aws_iam_policy" "external_secrets_policy" {
  name        = "ExternalSecretsPolicy"
  description = "IAM policy for External Secrets to access AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:*"
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets_role" {
  name = "ExternalSecretsIRSA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  policy_arn = aws_iam_policy.external_secrets_policy.arn
  role       = aws_iam_role.external_secrets_role.name
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "ExternalDnsPolicy"
  path        = "/"
  description = "IAM policy for External DNS"
  policy      = file("${path.module}/route53policy.json")
}

resource "aws_iam_role" "external_dns_role" {
  name = "ExternalDnsIRSA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  policy_arn = aws_iam_policy.external_dns_policy.arn
  role       = aws_iam_role.external_dns_role.name
}

resource "aws_route53_zone" "mydomain" {
  name = "mydomain.org"
}
