data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}

resource "kubernetes_namespace" "my_app_namespace" {
  metadata {
    name = "app"
  }
}

resource "kubernetes_config_map" "configmap" {
  metadata {
    name      = "my-configmap"
    namespace = kubernetes_namespace.my_app_namespace.metadata[0].name
  }

  data = {
    DB_URL = replace(var.rds_endpoint, ":5432", "")
  }
}

resource "kubernetes_secret" "argocd_repo" {
  depends_on = [kubernetes_config_map.configmap]
  metadata {
    name      = "argocd-repo-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.git_source_repoURL
    password = var.github_token
    username = "vgevorgyan009"
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "argocd_application" {
  depends_on = [kubernetes_secret.argocd_repo]
  manifest = yamldecode(templatefile("${path.module}/application.yaml", {
    path           = var.git_source_path
    repoURL        = var.git_source_repoURL
    targetRevision = var.git_source_targetRevision
  }))
}
