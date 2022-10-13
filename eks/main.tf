terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.24.0"
    }
  }

}

provider "aws" {
  region  = "us-east-1"
}

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.12.0"
  cluster_version           = "1.23"
  cluster_name                      = "eks-tests"
  vpc_id                    = "vpc-095099ed4074eb82e"                                     
  private_subnet_ids        = ["subnet-04ab150e2266c19aa",
                              "subnet-014dfafdd6dfbd14f",
                              "subnet-006ebe6ba3b8643c7",
                              "subnet-0afec5da6acc6047a" ]   
  managed_node_groups = {
    mg_t3 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["t3.large"]
      subnet_ids      =  ["subnet-04ab150e2266c19aa",
                              "subnet-014dfafdd6dfbd14f",
                              "subnet-006ebe6ba3b8643c7",
                              "subnet-0afec5da6acc6047a" ]  
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
  enable_prometheus                   = true

  kube_prometheus_stack_helm_config = {
    set = [
      {
        name  = "grafana.enabled"
        value = false
      },
      {
        name  = "kubelet.enabled"
        value = false
      },
      {
        name  = "kubeControllerManager.enabled"
        value = false
      },
      {
        name  = "coreDns.enabled"
        value = false
      },
      {
        name  = "kubeEtcd.enabled"
        value = false
      },
      {
        name  = "kubeScheduler.enabled"
        value = false
      },
      {
        name  = "kubeProxy.enabled"
        value = false
      },
    ],
   /*  set_sensitive = [
      {
        name  = "grafana.adminPassword"
        value = data.aws_secretsmanager_secret_version.admin_password_version.secret_string
      }
    ] */
  }
}