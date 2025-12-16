# This manifest is used to set up a Let's Encrypt-based certificate issuer and is made optional
# when providing a custom certificate for use with the frontend.
resource "kubernetes_manifest" "letsencrypt_cluster_issuer" {
  count                         = var.use_custom_certificate ? 0 : 1

  manifest = {
    "apiVersion"                = "cert-manager.io/v1"
    "kind"                      = var.cert_issuer_kind

    "metadata" = {
      "name"                    = var.cert_issuer_name
    }

    "spec" = {

      "acme" = {
        "email"                 = var.cert_issuer_email
        
        "privateKeySecretRef"   = {
          "name"                = var.cert_issuer_private_key
        }

        "server"                = var.cert_ca_server
        
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class"         = "nginx"
              }
            }
          },
        ]
      }
    }
  }
  
  depends_on = [ kubernetes_namespace_v1.cert_manager, helm_release.cert_manager, data.kubernetes_resources.check_cert_manager_crd ]
}

# Create a certificate with Let's Encrypt if the user did not provide a certificate
resource "kubernetes_manifest" "tls-cert-pub" {
  count                     = var.use_custom_certificate ? 0 : 1

  manifest = {
    apiVersion              = "cert-manager.io/v1"
    kind                    = "Certificate"
    metadata = {
        name = "${var.name_prefix}-tls-cert"
        namespace = "${var.k8s_namespace_prefix}"
    }

    spec = {
      secretName = "${var.name_prefix}-tls-cert-secret"
      issuerRef = {
        name = var.cert_issuer_name
        kind = var.cert_issuer_kind
      }

      commonName = var.logscale_public_fqdn
      dnsNames = [ var.logscale_public_fqdn ]
    }
  
  }
  depends_on = [ kubernetes_manifest.letsencrypt_cluster_issuer, kubernetes_namespace_v1.logscale-ingress ]
}