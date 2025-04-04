terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "myapp-tf-s3-bucket69"
    key    = "mytest4/state.tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {}

data "aws_iam_role" "eks_worker_role" {
  name = element(split("/", module.eks.eks_managed_node_groups[keys(module.eks.eks_managed_node_groups)[0]].iam_role_arn), 1)
}

data "aws_caller_identity" "current" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name            = "myapp-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name                   = "myapp-eks-cluster"
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 3
      max_size     = 6
      desired_size = 3

      instance_types = ["t3.small"]
    }
  }
}

module "RDS_DB" {
  source              = "./my-modules/RDS_module"
  vpc_id              = module.myapp-vpc.vpc_id
  node_security_group = module.eks.node_security_group_id
  subnet_ids          = module.myapp-vpc.private_subnets
  rds_username        = var.rds_username
  rds_password        = var.rds_password
}

module "IRSA" {
  source               = "./my-modules/IRSA_module"
  eks_worker_role_name = data.aws_iam_role.eks_worker_role.name
  region               = var.region
  account_id           = data.aws_caller_identity.current.account_id
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
}

module "helm" {
  source           = "./my-modules/helm_module"
  eks_cluster_name = "myapp-eks-cluster"
  chart_version    = "5.46.2"
  eks_dependency   = module.eks
  region           = var.region
  secrets_irsa_arn = module.IRSA.secrets_role_arn
  dns_irsa_arn     = module.IRSA.dns_role_arn
}
/*
module "kubernetes" {
  source             = "./my-modules/kubernetes_module"
  eks_cluster_name   = "myapp-eks-cluster"
  git_source_path    = "MyDbAppHelmChart"
  git_source_repoURL = "https://github.com/vgevorgyan009/my-task-3-infrastructure.git"
  github_token       = var.github_token
  rds_endpoint       = module.RDS_DB.db_endpoint
}
*/
