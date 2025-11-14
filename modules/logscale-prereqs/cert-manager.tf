# Check for cert-manager CRD
data "kubernetes_resources" "check_cert_manager_crd" {
  api_version    = "apiextensions.k8s.io/v1"
  kind           = "CustomResourceDefinition"
  field_selector = "metadata.name=clusterissuers.cert-manager.io"
}

# Deploy cert manager via helm
# This is primarily used for the creation of a Let's Encrypt certificate for the ingress frontend
resource "helm_release" "cert_manager" {
  count      = var.use_custom_certificate ? 0 : 1

  name       = "cert-manager"
  repository = var.cm_repo
  chart      = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager[0].metadata[0].name
  version    = var.cm_version

  values = [
    <<-EOT
    ingressShim:
      defaultIssuerName: var.issuer_name
      defaultIssuerKind: var.issuer_kind
    EOT
  ]
  depends_on = [
    kubernetes_namespace_v1.cert_manager
  ]
}