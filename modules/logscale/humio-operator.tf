/*
Create humio operator pods
*/
resource "helm_release" "humio_operator" {
  name         = "humio-operator"
  chart        = "humio-operator"
  repository   = var.humio_operator_repo
  namespace    = var.k8s_namespace_prefix
  version      = var.humio_operator_chart_version
  skip_crds    = true
  reset_values = true

  set {
    name  = "operator.image.tag"
    value = var.humio_operator_version
  }

  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = 60
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = 60
  }

  # When a custom certififcate is in use, cert-manager is not installed. Pending additional testing.
  set {
    name = "certmanager"
    #value = var.use_custom_certificate ? false : true
    value = true
  }

  dynamic "set" {
    for_each = [for key, value in var.humio_operator_extra_values : {
      helm_variable_name  = key
      helm_variable_value = value
    } if length(value) > 0]
    content {
      name  = set.value.helm_variable_name
      value = set.value.helm_variable_value
    }
  }

  depends_on = [
    data.kubernetes_resources.check_humio_cluster_crd
  ]

}

# The upstream chart hardcodes replicas to 1. Patch it to 0 for standby DR clusters after deployment.
# This must re-run after every Helm upgrade since Helm will reset replicas to 1.
resource "null_resource" "humio_operator_replica_patch" {
  count = var.dr == "standby" ? 1 : 0

  provisioner "local-exec" {
    command     = "kubectl patch deployment ${helm_release.humio_operator.name} -n ${var.k8s_namespace_prefix} -p '{\"spec\":{\"replicas\":0}}'"
    environment = var.kubeconfig_path != "" ? { KUBECONFIG = var.kubeconfig_path } : {}
  }

  triggers = {
    helm_revision = helm_release.humio_operator.metadata[0].revision
  }

  depends_on = [helm_release.humio_operator]
}

