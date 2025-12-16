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

resource "null_resource" "logscale_ns" {
  triggers = {
    namespace_name = var.k8s_namespace_prefix
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${var.k8s_namespace_prefix} --dry-run=client -o yaml | kubectl apply -f -"
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete namespace ${self.triggers.namespace_name} --timeout=60s --ignore-not-found=true"
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


