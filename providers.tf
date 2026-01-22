terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.1"
    }

    time = {
      source  = "hashicorp/time"
      version = ">=0.9.1"
    }

    http = {
      source  = "hashicorp/http"
      version = "~>3.4.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.31.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">=3.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.13.2,<3.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = var.k8s_cluster_context
}

provider "helm" {
  kubernetes {
    config_path    = var.k8s_config_path
    config_context = var.k8s_cluster_context
  }
}