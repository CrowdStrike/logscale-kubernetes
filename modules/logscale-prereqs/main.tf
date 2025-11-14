/** 
 * ## Module: kubernetes/logscale-prereqs
 * This module installs a number of prerequisites for running Logscale in Kubernetes to include:
 * * Kubernetes Namespaces
 * * Cert Manager
 * * Let's Encrypt Issuer manifest
 * * NGINX Ingress for managing connections to Logscale
 * * Topo LVM for managing storage on NVME-enabled nodes
 * 
 * Additionally, the module creates a number of kubernetes secrets used by Logscale. This way, you can change/destroy/reapply the Logscale
 * module without impact to these values.
 * 
 */


resource "kubernetes_manifest" "logscale_ns" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.k8s_namespace_prefix
    }
  }
}

resource "kubernetes_namespace_v1" "logscale-ingress" {
  metadata {
    name = "${var.k8s_namespace_prefix}-ingress"
  }
}

resource "kubernetes_namespace_v1" "logscale-topo" {
  metadata {
    name = "${var.k8s_namespace_prefix}-topolvm"
  }
}

resource "kubernetes_namespace_v1" "cert_manager" {
  #count                     = var.use_custom_certificate ? 0 : 1
  count                     = 1
  metadata {
    name = "${var.k8s_namespace_prefix}-cert"
  }
}


