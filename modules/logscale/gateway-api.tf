locals {
  ingest_node_selector_mapping = {
    # Advanced goes to ingest node pool
    "advanced" = { "humio.com/node-pool" = "${var.name_prefix}-ingest-only" }

    # Dedicated-ui and ingress go to digest node pool
    "dedicated-ui" = { "humio.com/node-pool" = "${var.name_prefix}" }
    "ingress"      = { "humio.com/node-pool" = "${var.name_prefix}" }

    # Basic goes to all nodes
    "basic" = { "app.kubernetes.io/name" = "humio" }

    # Default selection is the digest node pool
    "default" = { "humio.com/node-pool" = "${var.name_prefix}" }
  }

  ui_node_selector_mapping = {
    # Advanced goes to a dedicated ui node pool
    "advanced" = { "humio.com/node-pool" = "${var.name_prefix}-ui" }

    # Dedicated-ui goes to a dedicated ui node pool
    "dedicated-ui" = { "humio.com/node-pool" = "${var.name_prefix}-ui" }

    # Ingress goes to all nodes
    "ingress" = { "humio.com/node-pool" = "${var.name_prefix}" }

    # Basic goes to all nodes
    "basic" = { "app.kubernetes.io/name" = "humio" }

    # Default selection is to assume the digest nodes are being used for UI queries as well.
    "default" = { "humio.com/node-pool" = "${var.name_prefix}" }
  }

  # These annotations are applied to the ingress controller
  base_gateway_annotations = {
    # If using cert-manager, set the certificate issuer (null when using a provided certificate)
    "cert-manager.io/cluster-issuer" = (var.use_custom_certificate) ? null : var.cert_issuer_name

    # Do not allow cert-manager to edit the ingress controller directly
    "acme.cert-manager.io/http01-edit-in-place" = "false"
  }

  gateway_annotations = merge(local.base_gateway_annotations, var.extra_gateway_annotations)

  # DR-aware selectors with two-phase promotion support:
  #
  # For non-DR clusters (dr=""): Always use pool-specific selectors for optimized routing.
  #
  # For DR clusters (dr="standby" or dr="active"):
  #   - When dr_use_dedicated_routing=false (default):
  #     Use { "app.kubernetes.io/name" = "humio" } to match ALL LogScale pods.
  #     This ensures zero-downtime during DR promotion as the selector never changes.
  #
  #   - When dr_use_dedicated_routing=true (after UI/Ingest pods are ready):
  #     Use pool-specific selectors like non-DR clusters.
  #     UI traffic routes to UI pods, Ingest traffic routes to Ingest pods.
  #
  # Two-phase DR promotion workflow:
  # 1. First apply: dr="active", dr_use_dedicated_routing=false
  #    → Selector stays { "app.kubernetes.io/name" = "humio" }, traffic goes to digest pod
  # 2. Wait for UI/Ingest pods to be ready
  # 3. Second apply: dr="active", dr_use_dedicated_routing=true
  #    → Selector changes to pool-specific, traffic routes to dedicated pools
  effective_ingest_selector = (
    var.dr == "" ? lookup(local.ingest_node_selector_mapping, var.logscale_cluster_type, local.ingest_node_selector_mapping["default"]) :
    var.dr_use_dedicated_routing ? lookup(local.ingest_node_selector_mapping, var.logscale_cluster_type, local.ingest_node_selector_mapping["default"]) :
    { "app.kubernetes.io/name" = "humio" }
  )

  effective_ui_selector = (
    var.dr == "" ? lookup(local.ui_node_selector_mapping, var.logscale_cluster_type, local.ui_node_selector_mapping["default"]) :
    var.dr_use_dedicated_routing ? lookup(local.ui_node_selector_mapping, var.logscale_cluster_type, local.ui_node_selector_mapping["default"]) :
    { "app.kubernetes.io/name" = "humio" }
  )

  all_hostnames = concat([var.logscale_public_fqdn], var.ingress_extra_hostnames)
}

# Gateway resource - defines the load balancer and its configuration
resource "kubernetes_manifest" "logscale_gateway" {
  count = var.deploy_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name        = "${var.name_prefix}-gateway"
      namespace   = var.k8s_namespace_prefix
      annotations = local.gateway_annotations
    }
    spec = {
      gatewayClassName = var.gateway_class_name
      listeners = concat(
        [
          # HTTP listener for ACME HTTP-01 challenges (cert-manager gatewayHTTPRoute solver)
          {
            name     = "acme-http"
            port     = 80
            protocol = "HTTP"
            allowedRoutes = {
              namespaces = {
                from = "Same"
              }
            }
          }
        ],
        [
          for hostname in local.all_hostnames : {
            name     = replace(hostname, ".", "-")
            hostname = hostname
            port     = 443
            protocol = "HTTPS"
            tls = {
              mode = "Terminate"
              certificateRefs = [
                {
                  name = var.use_custom_certificate ? "${var.name_prefix}-tls-certificate" : hostname
                  kind = "Secret"
                }
              ]
            }
            allowedRoutes = {
              namespaces = {
                from = "Same"
              }
            }
          }
        ]
      )
    }
  }
}

resource "kubernetes_manifest" "gateway-class" {
  count = var.deploy_gateway_api ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "GatewayClass"
    metadata = {
      name      = "${var.name_prefix}-gateway-class"
    }

    spec = {
      controllerName = var.gateway_controller_name
      parametersRef = var.gateway_parameters_ref
    }
  }
}

resource "kubernetes_manifest" "logscale_ui_httproute" {
  for_each = var.deploy_gateway_api ? toset(local.all_hostnames) : toset([])

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name        = "${var.name_prefix}-ui-route-${replace(each.value, ".", "-")}"
      namespace   = var.k8s_namespace_prefix
      annotations = local.gateway_annotations
    }
    spec = {
      parentRefs = [
        {
          name        = kubernetes_manifest.logscale_gateway[0].manifest.metadata.name
          namespace   = var.k8s_namespace_prefix
          sectionName = replace(each.value, ".", "-")
        }
      ]
      hostnames = [each.value]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name   = kubernetes_service_v1.logscale_ui_clusterip_gw[0].metadata[0].name
              port   = 8080
              weight = 100
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.logscale_gateway]
}


# # HTTPRoute for ingest API traffic
# resource "kubernetes_manifest" "logscale_ingest_httproute" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "HTTPRoute"
#     metadata = {
#       name      = "${var.name_prefix}-ingest-route"
#       namespace = var.k8s_namespace_prefix
#     }
#     spec = {
#       parentRefs = [
#         {
#           name      = kubernetes_manifest.logscale_gateway.manifest.metadata.name
#           namespace = var.k8s_namespace_prefix
#         }
#       ]
#       hostnames = concat([var.logscale_public_fqdn], var.ingress_extra_hostnames)
#       rules = [
#         {
#           matches = [
#             {
#               path = {
#                 type  = "PathPrefix"
#                 value = "/api/v1/ingest/"
#               }
#             }
#           ]
#           backendRefs = [
#             {
#               name = kubernetes_service_v1.logscale_ingest_clusterip_gw.metadata[0].name
#               port = 8080
#               weight = 100
#             }
#           ]
#         }
#       ]
#     }
#   }

#   depends_on = [kubernetes_manifest.logscale_gateway]
# }

# Updated service resources to work with Gateway API
resource "kubernetes_service_v1" "logscale_ingest_clusterip_gw" {
  count = var.deploy_gateway_api ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ingest-cip-gw"
    namespace = var.k8s_namespace_prefix
  }

  spec {
    type     = "ClusterIP"
    selector = local.effective_ingest_selector
    port {
      port        = 8080
      target_port = 8080
      name        = "http"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service_v1" "logscale_ui_clusterip_gw" {
  count = var.deploy_gateway_api ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ui-cip-gw"
    namespace = var.k8s_namespace_prefix
  }

  spec {
    type     = "ClusterIP"
    selector = local.effective_ui_selector
    port {
      port        = 8080
      target_port = 8080
      name        = "http"
      protocol    = "TCP"
    }
  }
}