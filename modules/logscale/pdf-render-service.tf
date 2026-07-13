locals {
  pdfrenderservice_manifest_kind = "HumioPdfRenderService"
}

# Define the humio cluster based on our given inputs
resource "kubernetes_manifest" "pdf_render_service" {
  count = var.enable_pdf_render_service ? 1 : 0
  manifest = {
    apiVersion = local.humio_manifest_api_version
    kind       = local.pdfrenderservice_manifest_kind

    metadata = {
      name      = "${var.name_prefix}-pdf-render-service"
      namespace = local.logscale_kubernetes_namespace
    }

    spec = {
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "kubernetes.io/arch"
                    operator = "In"
                    values   = ["amd64"]
                  },
                  {
                    key      = "kubernetes.io/os"
                    operator = "In"
                    values   = ["linux"]
                  },
                  {
                    key      = "k8s-app"
                    operator = "In"
                    values   = ["logscale-digest"]
                  }
                ]
              }
            ]
          }
        }
      }

      volumeMounts = [
        {
          name      = "app-temp"
          mountPath = "/app/temp"
        },
        {
          name      = "tmp"
          mountPath = "/tmp"
        }
      ]

      volumes = [
        {
          name = "app-temp"
          emptyDir = {
            medium = "Memory"
          }
        },
        {
          name = "tmp"
          emptyDir = {
            medium = "Memory"
          }
        }
      ]

      containerSecurityContext = {
        allowPrivilegeEscalation = false
        capabilities = {
          drop = ["ALL"]
        }
        privileged             = false
        readOnlyRootFilesystem = true
        runAsGroup             = 1000
        runAsNonRoot           = true
        runAsUser              = 1000
      }

      environmentVariables = [
        {
          name  = "XDG_CONFIG_HOME"
          value = "/tmp/.chromium-config"
        },
        {
          name  = "XDG_CACHE_HOME"
          value = "/tmp/.chromium-cache"
        },
        {
          name  = "LOG_LEVEL"
          value = "debug"
        },
        {
          name  = "CLEANUP_INTERVAL"
          value = "600"
        }
      ]

      image    = var.pdf_render_service_image
      replicas = var.pdf_render_service_node_count
      resources = {
        limits = {
          cpu    = "1",
          memory = "2Gi"
        }
        requests = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
      serviceType = "ClusterIP"
      port        = var.pdf_render_service_port
      tls = {
        enabled      = true
        caSecretName = "${var.name_prefix}-ca-keypair"
      }
      readinessProbe = {
        httpGet = {
          path = "/ready"
          port = var.pdf_render_service_port
        }
        initialDelaySeconds = 30
        periodSeconds       = 15
        timeoutSeconds      = 60
        failureThreshold    = 1
        successThreshold    = 1
      }
      livenessProbe = {
        "failureThreshold" = 5
        "httpGet" = {
          "path" = "/health"
          "port" = var.pdf_render_service_port
        }
        "initialDelaySeconds" = 30
        "periodSeconds"       = 15
        "successThreshold"    = 1
        "timeoutSeconds"      = 60
      }
      annotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/path"   = "/metrics"
        "prometheus.io/port"   = var.pdf_render_service_port
      }
    }
  }

  depends_on = [data.kubernetes_resources.check_humio_cluster_crd]

  computed_fields = ["metadata.labels"]

  field_manager {
    name            = "tfapply"
    force_conflicts = true
  }
}
