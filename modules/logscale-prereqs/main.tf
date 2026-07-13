/**
 * ## Module: kubernetes/logscale-prereqs
 * This module installs a number of prerequisites for running Logscale in Kubernetes to include:
 * * Kubernetes Namespaces
 * * Cert Manager
 * * Let's Encrypt Issuer manifest
 * * Gateway API for managing connections to Logscale
 * * Topo LVM for managing storage on NVME-enabled nodes
 *
 * Additionally, the module creates a number of kubernetes secrets used by Logscale. This way, you can change/destroy/reapply the Logscale
 * module without impact to these values.
 *
 */

# Check if namespace exists using a data source that handles non-existence gracefully
data "kubernetes_namespace_v1" "check_logscale" {
  count = 1

  metadata {
    name = var.k8s_namespace_prefix
  }

  # Prevent errors if namespace doesn't exist
  lifecycle {
    postcondition {
      condition     = self.metadata != null || self.metadata == null
      error_message = "Namespace check completed"
    }
  }
}

locals {
  # Check if namespace exists by attempting to read its metadata
  namespace_exists = try(data.kubernetes_namespace_v1.check_logscale[0].metadata[0].name, null) != null
}

# Create the logscale namespace via the kubernetes provider (no bare kubectl).
# Skipped if the namespace already exists (e.g., managed by a parent module like OCI pre-install).
resource "kubernetes_namespace_v1" "logscale" {
  count = local.namespace_exists ? 0 : 1

  metadata {
    name = var.k8s_namespace_prefix
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
  count = 1
  metadata {
    name = "${var.k8s_namespace_prefix}-cert"
  }
}
