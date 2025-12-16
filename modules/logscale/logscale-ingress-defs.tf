locals {
  ingest_node_selector_mapping = {
    # Advanced goes to ingest node pool
    "advanced"      = { "humio.com/node-pool" = "${var.name_prefix}-ingest-only" }

    # Dedicated-ui and ingress go to digest node pool
    "dedicated-ui"  = { "humio.com/node-pool" = "${var.name_prefix}" }
    "ingress"       = { "humio.com/node-pool" = "${var.name_prefix}" }

    # Basic goes to all nodes
    "basic"         = { "app.kubernetes.io/name" = "humio" }

    # Default selection is the digest node pool
    "default"       = { "humio.com/node-pool" = "${var.name_prefix}" }
  }

  ui_node_selector_mapping = {
    # Advanced goes to a dedicated ui node pool
    "advanced"      = { "humio.com/node-pool" = "${var.name_prefix}-ui" }

    # Dedicated-ui goes to a dedicated ui node pool
    "dedicated-ui"  = { "humio.com/node-pool" = "${var.name_prefix}-ui" }

    # Ingress goes to all nodes
    "ingress"       = { "humio.com/node-pool" = "${var.name_prefix}" }

    # Basic goes to all nodes
    "basic"         = { "app.kubernetes.io/name" = "humio" }

    # Default selection is to assume the digest nodes are being used for UI queries as well.
    "default"       = { "humio.com/node-pool" = "${var.name_prefix}" }
  }

  # These annotations are applied to the ingress controller
  base_nginx_annotations = {
    # Set backend to use HTTPS when intracluster is TLS enabled
    "nginx.ingress.kubernetes.io/backend-protocol"                    = "HTTPS"

    # Request affinity based on session cookie
    "nginx.ingress.kubernetes.io/affinity"                            = "cookie"
    "nginx.ingress.kubernetes.io/affinity-mode"                       = "balanced"

    # Session cookie settings
    "nginx.ingress.kubernetes.io/session-cookie-name"                 = "LSINGCOOKIE"
    "nginx.ingress.kubernetes.io/session-cookie-secure"               = "true"
    "nginx.ingress.kubernetes.io/session-cookie-max-age"              = "86400"
    "nginx.ingress.kubernetes.io/session-cookie-change-on-failure"    = "true"

    # Redirect all frontend requests to use tls
    "nginx.ingress.kubernetes.io/ssl-redirect"                        = "true"

    # Forward headers to backend
    "nginx.ingress.kubernetes.io/use-forwarded-headers"               = "true"
    "nginx.ingress.kubernetes.io/proxy-set-header"                    = "X-Forwarded-For $proxy_add_x_forwarded_for"
    "nginx.ingress.kubernetes.io/proxy-set-header"                    = "X-Forwarded-Proto $scheme"

    # Set max body size for requests
    "nginx.ingress.kubernetes.io/proxy-body-size"                     = "16m"

    # Turn off disk-based request buffering
    "nginx.ingress.kubernetes.io/proxy-request-buffering"             = "off"
    "nginx.ingress.kubernetes.io/proxy-buffering"                     = "off"

    # Set timeouts for connect, send, and read
    "nginx.ingress.kubernetes.io/proxy-send-timeout"                  = "300"
    "nginx.ingress.kubernetes.io/proxy-read-timeout"                  = "300"
    "nginx.ingress.kubernetes.io/proxy-connect-timeout"               = "300"

    # Prefer server-set tls ciphers
    "nginx.ingress.kubernetes.io/ssl-prefer-server-ciphers"           = "true"

    # Explicitly set tls protocols and ciphers for use with nginx
    "nginx.ingress.kubernetes.io/proxy-ssl-protocols"                 = "TLSv1.2 TLSv1.3"
    "nginx.ingress.kubernetes.io/ssl-ciphers"                         = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"

    # Cycle to next upstream server when these error conditions are met
    "nginx.ingress.kubernetes.io/proxy-next-upstream"                 = "error timeout http_502 http_503 http_504"

    # If using cert-manager, set the certificate issuer (null when using a provided certificate)
    "cert-manager.io/cluster-issuer"                                  = (var.use_custom_certificate) ? null : var.cert_issuer_name

    # Do not allow cert-manager to edit the ingress controller directly
    "acme.cert-manager.io/http01-edit-in-place"                       = "false"
  }

  nginx_annotations = merge(local.base_nginx_annotations, var.extra_nginx_annotations)
}

# This will serve as the default ingest ClusterIP for nginx ingress
resource "kubernetes_service" "logscale_ingest_clusterip" {
  count = var.enable_nginx_ingress ? 1 : 0
  
  metadata {
    name                  = "${var.name_prefix}-ingest-cip"
    namespace             = "${var.k8s_namespace_prefix}"
  }

  spec {
    type                  = "ClusterIP"
    selector              = lookup(local.ingest_node_selector_mapping, var.logscale_cluster_type, "default")
    port {
      port                = 8080
      target_port         = 8080
      name                = "logscale-port"
    }
  }
}

# This ClusterIP will serve as the dedicated UI point for nginx ingress
resource "kubernetes_service" "logscale_ui_clusterip" {
  count = var.enable_nginx_ingress ? 1 : 0
  
  metadata {
    name                  = "${var.name_prefix}-ui-cip"
    namespace             = "${var.k8s_namespace_prefix}"
  }

  spec {
    type                  = "ClusterIP"
    selector              = lookup(local.ui_node_selector_mapping, var.logscale_cluster_type, "default")
    port {
      port                = 8080
      target_port         = 8080
      name                = "logscale-port"
    }
  }
}

# ingress resource for nginx (AWS, Azure, etc.)
resource "kubernetes_ingress_v1" "logscale_ingress_ui" {
  count = var.enable_nginx_ingress ? 1 : 0
  
  metadata {
    name                      = "${var.name_prefix}-ui"
    namespace                 = "${var.k8s_namespace_prefix}"
    annotations               = local.nginx_annotations
  }
  spec {
    ingress_class_name        = var.ingress_class_name
    tls {
      hosts                   = [ var.logscale_public_fqdn ]
      secret_name             = (var.use_custom_certificate) ? "${var.name_prefix}-tls-certificate" : "${var.logscale_public_fqdn}"
    }

    rule {
      host                    = "${var.logscale_public_fqdn}"

      http {
        path {
          path                = "/"
          path_type           = "Prefix"
          backend {
            service {
              name            = kubernetes_service.logscale_ui_clusterip[0].metadata[0].name
              port {
                number        = 8080
              }
            }
          }
        }
      }
    }

    rule {
      host                    = "${var.logscale_public_fqdn}"

      http {
        path {
          path                = "/api/v1/ingest/"
          path_type           = "Prefix"
          backend {
            service {
              name            = kubernetes_service.logscale_ingest_clusterip[0].metadata[0].name
              port {
                number        = 8080
              }
            }
          }
        }
      }
    }
  }
}
