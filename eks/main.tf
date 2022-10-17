terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.24.0"
    }
  }

}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

data "aws_eks_cluster" "cluster" {
  name = "infra-tools"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "infra-tools"
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks_blueprints" {
  source          = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.12.0"
  cluster_version = "1.23"
  cluster_name    = "infra-tools"
  vpc_id          = "vpc-095099ed4074eb82e"
  private_subnet_ids = ["subnet-04ab150e2266c19aa",
    "subnet-006ebe6ba3b8643c7"]
  managed_node_groups = {
    mg_t3 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.large"]
      desired_size    = 1
      max_size        = 1
      min_size        = 1
      subnet_ids = ["subnet-04ab150e2266c19aa",
        "subnet-006ebe6ba3b8643c7"]
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.12.0"

  eks_cluster_id = module.eks_blueprints.eks_cluster_id

  # EKS Addons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  #K8s Add-ons
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true  
  enable_kube_prometheus_stack      = true
  kube_prometheus_stack_helm_config = {
    values = [templatefile("./k8s_values/shared.yaml", {}), 
              templatefile("./k8s_values/observer/observer.yaml", {})]
  }
}

module "observee" {
  source          = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.12.0"
  cluster_version = "1.23"
  cluster_name    = "observee"
  vpc_id          = "vpc-095099ed4074eb82e"
  private_subnet_ids = ["subnet-04ab150e2266c19aa",
    "subnet-006ebe6ba3b8643c7"]
  managed_node_groups = {
    mg_t3 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.large"]
      desired_size    = 1
      max_size        = 1
      min_size        = 1
      subnet_ids = ["subnet-04ab150e2266c19aa",
        "subnet-006ebe6ba3b8643c7"]
    }
  }
}

module "observee_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.12.0"

  eks_cluster_id = module.observee.eks_cluster_id

  # EKS Addons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  #K8s Add-ons
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_kube_prometheus_stack      = true
  kube_prometheus_stack_helm_config = {
    chart = "kube-prometheus-stack"
    values = [templatefile("./k8s_values/shared.yaml", {}), 
              templatefile("./k8s_values/prod.yaml", {})]
  }
}
