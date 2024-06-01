terraform {
  backend "s3" {
    bucket = "terraform-backend-state-in28minutes-123"
    key    = "path/to/your/terraform/state"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Default VPC
resource "aws_default_vpc" "default" {}

# Get Subnets from the Default VPC
data "aws_subnet_ids" "subnets" {
  vpc_id = aws_default_vpc.default.id
}

# EKS Cluster module
module "in28minutes-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.0.0"
  cluster_name    = "in28minutes-cluster"
  cluster_version = "1.14"
  subnets         = data.aws_subnet_ids.subnets.ids
  vpc_id          = aws_default_vpc.default.id

  node_groups = {
    in28minutes-ng = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3

      instance_type = "t2.micro"
    }
  }
}

# EKS Cluster data source
data "aws_eks_cluster" "cluster" {
  depends_on = [module.in28minutes-cluster]
  name = module.in28minutes-cluster.cluster_id
}

# EKS Cluster authentication
data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.in28minutes-cluster]
  name = module.in28minutes-cluster.cluster_id
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  version                = "~> 2.12"
}

# Kubernetes ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}
