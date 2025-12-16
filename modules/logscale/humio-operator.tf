/*
Create humio operator pods
*/
resource "helm_release" "humio_operator" {
  name         = "humio-operator"
  repository   = var.humio_operator_repo
  chart        = "humio-operator"
  namespace    = "${var.k8s_namespace_prefix}"
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