
/*
Deploy a generic nginx ingress controller for accessing logscale services
*/
resource "helm_release" "nginx_ingress" {
  count     = var.deploy_nginx_ingress ? 1 : 0
  name      = "${var.name_prefix}-nginx"
  namespace = kubernetes_namespace_v1.logscale-ingress.metadata[0].name

  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = var.nginx_ingress_helm_chart_version
  chart      = "ingress-nginx"

  # Increased timeout to accommodate cloud provider RBAC propagation delays
  # Azure role assignments can take up to 10 minutes to propagate
  timeout = 900

  dynamic "set" {
    for_each = var.nginx_ingress_sets

    content {
      name  = set.value["name"]
      value = set.value["value"]
    }
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "controller.autoscaling.targetCPUUtilizationPercentage"
    value = "65"
  }

  set {
    name  = "controller.autoscaling.targetMemoryUtilizationPercentage"
    value = "65"
  }

  /* Templatize these items */
  set {
    name  = "controller.replicaCount"
    value = var.logscale_ingress_pod_count
  }

  set {
    name  = "controller.autoscaling.minReplicas"
    value = var.logscale_ingress_min_pod_count
  }

  set {
    name  = "controller.autoscaling.maxReplicas"
    value = var.logscale_ingress_max_pod_count
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.logscale_ingress_resources["requests"]["cpu"]
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.logscale_ingress_resources["requests"]["memory"]
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = var.logscale_ingress_resources["limits"]["cpu"]
  }

  set {
    name  = "controller.resources.limits.memory"
    value = var.logscale_ingress_resources["limits"]["memory"]
  }

  // In cluster type "basic", the controller will exist on the system node
  // In any other cluster type, we're expecting a dedicated node group.
  dynamic "set" {
    for_each = var.logscale_cluster_type != "basic" ? [1] : []
    content {
      name  = "controller.nodeSelector.k8s-app"
      value = "logscale-ingress"
    }
  }
}