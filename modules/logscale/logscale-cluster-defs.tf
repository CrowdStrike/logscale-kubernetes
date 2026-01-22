# This locals block is largely here to move repeated configurations out of the HumioCluster 
# kubernetes manifest definitions to a single place so that updates are applied consistently
# to all architecture types.
# Doc ref: https://github.com/humio/humio-operator/blob/master/docs/api.md#humiocluster

locals {
  # The namespace that will be used by all resources created from these manifests
  logscale_kubernetes_namespace = var.k8s_namespace_prefix

  # The desired number of digest partitions
  digest_partitions_count = 840

  # Hostname is the public hostname used by clients to access logscale
  logscale_hostname = var.logscale_public_fqdn

  # This is the image to use for installing logscale
  logscale_image   = var.logscale_image != null ? var.logscale_image : "humio/humio-core:${var.logscale_image_version}"
  imagePullSecrets = var.logscale_image != null ? [{ name = var.image_pull_secret }] : []

  # The kubernetes secret containing the strimzi cert for our nodes to connect to the cluster
  kafka_truststore_secret_name = "${var.name_prefix}-strimzi-kafka-cluster-ca-cert"

  # Enable/Disable TLS for logscale intracluster communications
  # NOTE: caSecretName is intentionally NOT set here. Setting it does NOT fix CA mismatch issues because:
  # - The humio-operator reads CA from cluster TLS secret ({cluster-name}), not from caSecretName
  # - See clusterinterface.go line 213: reads from c.managedClusterName, not getCASecretName()
  # For DR standby deployments, the fix is to delete the stale TLS secret before scaling up the operator.
  # This is typically implemented in the DR failover automation.
  logscale_tls_spec = {
    enabled = true
  }

  # Environment variables to apply to all humiocluster pods
  commonEnvironmentVariables = concat([
    {
      name  = "KAFKA_COMMON_SECURITY_PROTOCOL"
      value = "SSL"
    },
    {
      name  = "USING_EPHEMERAL_DISKS"
      value = "true"
    },
    {
      name  = "LOCAL_STORAGE_PERCENTAGE"
      value = "80"
    },
    {
      name  = "LOCAL_STORAGE_MIN_AGE_DAYS"
      value = "1"
    },
    {
      name  = "KAFKA_BOOTSTRAP_SERVERS"
      value = var.kafka_broker_servers
    },
    {
      name  = "KAFKA_SERVERS"
      value = var.kafka_broker_servers
    },
    {
      name  = "PUBLIC_URL"
      value = "https://${var.logscale_public_fqdn}"
    },
    {
      name  = "AUTHENTICATION_METHOD"
      value = "static"
    },
    {
      name = "STATIC_USERS"
      valueFrom = {
        secretKeyRef = {
          key  = "users"
          name = var.k8s_secret_static_user_logins
        }
      }
    },
    {
      name  = "KAFKA_COMMON_SSL_TRUSTSTORE_TYPE"
      value = "PKCS12"
    },
    {
      name = "KAFKA_COMMON_SSL_TRUSTSTORE_PASSWORD"
      valueFrom = {
        secretKeyRef = {
          key  = "ca.password"
          name = local.kafka_truststore_secret_name
        }
      }

    },
    {
      name  = "KAFKA_COMMON_SSL_TRUSTSTORE_LOCATION"
      value = "/tmp/kafka/ca.p12"
    },
    ],
    var.enable_pdf_render_service ? local.pdf_render_service_env_vars : []
  )

  pdf_render_service_env_vars = [
    {
      name  = "DEFAULT_PDF_RENDER_SERVICE_URL"
      value = "http://pdf-render-service:${var.pdf_render_service_port}"
    },
    {
      name  = "ENABLE_SCHEDULED_REPORT"
      value = var.enable_scheduled_report
    },
  ]

  # DR recovery environment variables with simple string values
  # Keep these env vars in BOTH standby AND active DR modes to prevent pod recreation during promotion.
  # The env vars are only used at startup by DataSnapshotLoader and are safely ignored after recovery.
  # Changing env vars during promotion (standby → active) would change the pod hash in humio-operator,
  # triggering pod recreation and data loss with ephemeral PVCs.
  dr_recovery_simple_envvars = var.dr == "" ? [] : concat(
    var.bucket_recover_from_replace_region != null ? [
      {
        name  = "S3_RECOVER_FROM_REPLACE_REGION"
        value = var.bucket_recover_from_replace_region
      }
    ] : [],
    var.bucket_recover_from_replace_bucket != null ? [
      {
        name  = "S3_RECOVER_FROM_REPLACE_BUCKET"
        value = var.bucket_recover_from_replace_bucket
      }
    ] : [],
    var.bucket_recover_from_bucket != null ? [
      {
        name  = "S3_RECOVER_FROM_BUCKET"
        value = var.bucket_recover_from_bucket
      }
    ] : [],
    var.bucket_recover_from_region != null ? [
      {
        name  = "S3_RECOVER_FROM_REGION"
        value = var.bucket_recover_from_region
      }
    ] : [],
    var.bucket_recover_from_endpoint_base != null ? [
      {
        name  = "S3_RECOVER_FROM_ENDPOINT_BASE"
        value = var.bucket_recover_from_endpoint_base
      }
    ] : [],
    var.bucket_recover_from_path_style_access != null ? [
      {
        name  = "S3_RECOVER_FROM_PATH_STYLE_ACCESS"
        value = tostring(var.bucket_recover_from_path_style_access)
      }
    ] : [],
    var.dr == "standby" ? [
      {
        name  = "ENABLE_ALERTS"
        value = "false"
      }
    ] : []
  )

  # DR recovery environment variables with secretKeyRef
  # Keep these env vars in BOTH standby AND active DR modes to prevent pod recreation during promotion.
  dr_recovery_secret_envvars = var.dr == "" ? [] : (
    var.bucket_recover_from_encryption_key_secret_name != null && var.bucket_recover_from_encryption_key_secret_key != null ? [
      {
        name = "S3_RECOVER_FROM_ENCRYPTION_KEY"
        valueFrom = {
          secretKeyRef = {
            name = var.bucket_recover_from_encryption_key_secret_name
            key  = var.bucket_recover_from_encryption_key_secret_key
          }
        }
      }
    ] : []
  )

  # Combine all DR recovery environment variables
  dr_recovery_envvars = concat(local.dr_recovery_simple_envvars, local.dr_recovery_secret_envvars)

  baseEnvironmentVariables = concat(local.commonEnvironmentVariables, local.dr_recovery_envvars)

  # If this is a bring-your-own-kafka situation, we need to remove these settings from the above list
  kafka_env_configs_remove = ["KAFKA_COMMON_SSL_TRUSTSTORE_TYPE", "KAFKA_COMMON_SSL_TRUSTSTORE_PASSWORD", "KAFKA_COMMON_SSL_TRUSTSTORE_LOCATION"]

  extraHumioVolumeMounts = [
    # Extra Humio volume mounts
  ]
  extraHumioVolumes = [
    # Extra Humio volumes
  ]
  # These mount options are for mounting the strimzi kafka certificate store for connecting to the cluster
  extraKafkaTrustStoreVolumeMounts = [
    {
      mountPath = "/tmp/kafka/"
      name      = "trust-store"
      readOnly  = true
    }
  ]
  extraKafkaTrustStoreVolume = [
    {
      name = "trust-store"
      secret = {
        secretName = local.kafka_truststore_secret_name
      }
    }
  ]

  # This defines the data disk attached to DIGEST pods
  digest_data_volume_source_def = {
    ephemeral = {
      volumeClaimTemplate = {
        spec = {
          accessModes = ["ReadWriteOnce"]
          resources = {
            requests = {
              storage = var.logscale_digest_data_disk_size
            }
          }
          storageClassName = var.kube_storage_class_for_logscale
        }
      }
    }
  }

  # Pod/Node affinity specifications for DIGEST pods
  digest_node_affinity_def = {
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
              },
            ]
          },
        ]
      }
    }
    podAntiAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = [
        {
          labelSelector = {
            matchExpressions = [
              {
                key      = "app.kubernetes.io/name"
                operator = "In"
                values   = ["humio"]
              },
            ]
          }
          topologyKey = "kubernetes.io/hostname"
        },
      ]
    }
  }

  # The logscale license definition, expected to be a secret in kubernetes
  logscale_license_ref = {
    secretKeyRef = {
      key  = "humio-license-key"
      name = var.k8s_secret_logscale_license
    }
  }

  # Resource limits for DIGEST pods
  logscale_digest_resources_spec = {
    limits = {
      cpu    = var.logscale_digest_resources["limits"]["cpu"],
      memory = var.logscale_digest_resources["limits"]["memory"]
    },
    requests = {
      cpu    = var.logscale_digest_resources["requests"]["cpu"]
      memory = var.logscale_digest_resources["requests"]["memory"]
    }
  }

  # The number of digest pods we will run
  # For standby DR clusters: set to 1 to keep a single digest pod ready for serving traffic
  # Note: The humio-operator replicas is set to 0 for standby, so no pods will be created until failover
  logscale_digest_node_count = var.dr == "standby" ? 1 : var.logscale_digest_pod_count

  # TargetReplicationFactor is the desired number of replicas of both storage and ingest partitions
  # For standby DR clusters: set to 1 (minimum viable value) even when nodeCount is 0
  # When DR traffic detector scales nodeCount from 0 to 1, replication factor of 1 allows the single node to function
  target_replication_factor = var.dr == "standby" ? 1 : var.target_replication_factor

  # HumioCluster kubernetes manifest settings
  humiocluster_manifest_api_version = "core.humio.com/v1alpha1"
  humiocluster_manifest_kind        = "HumioCluster"

  # Alias for pdf-render-service.tf
  humio_manifest_api_version = local.humiocluster_manifest_api_version

  ui_node_pool_spec = {
    name = "ui"
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
                    values   = ["logscale-ui"]
                  }
                ]
              }
            ]
          }
        }

        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [
            {
              labelSelector = {
                matchExpressions = [
                  {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["humio"]
                  }
                ]
              }
              topologyKey = "kubernetes.io/hostname"
            }
          ]
        }
      }

      dataVolumePersistentVolumeClaimSpecTemplate = {
        accessModes = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = var.logscale_ui_data_disk_size
          }
        }
        storageClassName = var.kube_storage_class_for_logscale_ui
      }

      environmentVariables = [
        {
          name  = "NODE_ROLES"
          value = "httponly"
        },
        {
          name  = "INITIAL_DISABLED_NODE_TASK"
          value = "digest,storage"
        }
      ]

      extraHumioVolumeMounts         = local.extraHumioVolumeMounts_filtered
      extraVolumes                   = local.extraVolumes_filtered // ISSUE
      humioServiceAccountAnnotations = length(var.humio_service_account_annotations) > 0 ? var.humio_service_account_annotations : null
      image                          = local.logscale_image

      imagePullSecrets = local.imagePullSecrets

      nodeCount = var.dr == "standby" ? 0 : var.logscale_ui_pod_count
      resources = {
        limits = {
          cpu    = var.logscale_ui_resources["limits"]["cpu"],
          memory = var.logscale_ui_resources["limits"]["memory"]
        }
        requests = {
          cpu    = var.logscale_ui_resources["requests"]["cpu"]
          memory = var.logscale_ui_resources["requests"]["memory"]
        }
      }
      updateStrategy = var.logscale_update_strategy
    }
  }

  ingest_node_pool_spec = {
    name = "ingest-only"
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
                    values   = ["logscale-ingest"]
                  }
                ]
              }
            ]
          }
        }
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [
            {
              labelSelector = {
                matchExpressions = [
                  {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["humio"]
                  }
                ]
              }
              topologyKey = "kubernetes.io/hostname"
            }
          ]
        }
      }

      dataVolumePersistentVolumeClaimSpecTemplate = {
        accessModes = ["ReadWriteOnce"]
        resources = {
          requests = {
            storage = var.logscale_ingest_data_disk_size
          }
        }
        storageClassName = var.kube_storage_class_for_logscale_ingest
      }

      environmentVariables = [
        {
          name  = "NODE_ROLES"
          value = "ingestonly"
        },
        {
          name  = "INITIAL_DISABLED_NODE_TASK"
          value = "digest,query,storage"
        }
      ]
      extraHumioVolumeMounts         = local.extraHumioVolumeMounts_filtered
      extraVolumes                   = local.extraVolumes_filtered
      humioServiceAccountAnnotations = length(var.humio_service_account_annotations) > 0 ? var.humio_service_account_annotations : null
      image                          = local.logscale_image
      imagePullSecrets               = local.imagePullSecrets

      nodeCount = var.dr == "standby" ? 0 : var.logscale_ingest_pod_count
      resources = {
        limits = {
          cpu    = var.logscale_ingest_resources["limits"]["cpu"],
          memory = var.logscale_ingest_resources["limits"]["memory"]
        }
        requests = {
          cpu    = var.logscale_ingest_resources["requests"]["cpu"]
          memory = var.logscale_ingest_resources["requests"]["memory"]
        }
      }
      updateStrategy = var.logscale_update_strategy
    }
  }

  node_pool_mapping = {
    "basic"        = null
    "ingress"      = null
    "dedicated-ui" = [local.ui_node_pool_spec]
    "advanced"     = [local.ui_node_pool_spec, local.ingest_node_pool_spec]
  }

  ##### FILTERS #####
  # These are here to filter out the kafka related settings when strimzi is not used as the kafka source
  extraHumioVolumeMounts_filtered = var.provision_kafka_servers ? concat(local.extraHumioVolumeMounts, local.extraKafkaTrustStoreVolumeMounts) : length(local.extraHumioVolumeMounts) > 0 ? local.extraHumioVolumeMounts : null
  extraVolumes_filtered           = var.provision_kafka_servers ? concat(local.extraHumioVolumes, local.extraKafkaTrustStoreVolume) : length(local.extraHumioVolumes) > 0 ? local.extraHumioVolumes : null
  # extraVolumes_filtered = local.extraHumioVolumes
  commonEnvironmentVariables_filtered = [for m in local.baseEnvironmentVariables : m if(!(contains(local.kafka_env_configs_remove, m.name)) || var.provision_kafka_servers)]

  # This is here to merge together user provided variables with environment variables set above
  cevmap = { for e in local.commonEnvironmentVariables_filtered : e.name => e }
  uevmap = { for e in var.user_logscale_envvars : e.name => e }

  # This will merge the locally defined environment settings with user defined settings giving preference to user settings
  mergedmap = merge(local.cevmap, local.uevmap)

  # And this will get a final list of configuration settings allowing for normal values and valueFrom
  # IMPORTANT: All objects must have consistent structure for kubernetes_manifest type inference.
  # We filter to separate value-based vs valueFrom-based env vars to maintain type consistency.
  final_logscale_value_envvars = [
    for name in keys(local.mergedmap) : {
      name  = name
      value = tostring(local.mergedmap[name].value)
    } if try(local.mergedmap[name].value, null) != null
  ]

  final_logscale_valuefrom_envvars = [
    for name in keys(local.mergedmap) : {
      name      = name
      valueFrom = local.mergedmap[name].valueFrom
    } if try(local.mergedmap[name].valueFrom, null) != null
  ]

  final_logscale_configuration_vars = concat(
    local.final_logscale_value_envvars,
    local.final_logscale_valuefrom_envvars
  )


  ###################

  # For DR standby clusters, we MUST maintain the same node pool structure as active clusters
  # to enable seamless scaling during promotion. Setting nodePools to null for standby caused
  # the humio-operator to interpret the promotion as a structural change requiring pod recreation
  # rather than a simple scale operation.
  #
  # By keeping the same node pool definitions (with nodeCount=0 for ui/ingest pools in standby),
  # the promotion from standby to active only changes replica counts, not the pool structure.
  # This allows the humio-operator to scale existing pods instead of replacing them.
  #
  # The individual pool specs already handle DR mode via their nodeCount settings:
  # - ui_node_pool_spec.nodeCount = var.dr == "standby" ? 0 : var.logscale_ui_pod_count
  # - ingest_node_pool_spec.nodeCount = var.dr == "standby" ? 0 : var.logscale_ingest_pod_count
  selected_node_pools = lookup(local.node_pool_mapping, var.logscale_cluster_type, "basic")
  base_humio_cluster_spec = {
    affinity                   = local.digest_node_affinity_def
    autoRebalancePartitions    = var.dr == "standby" ? false : true
    dataVolumeSource           = local.digest_data_volume_source_def
    digestPartitionsCount      = local.digest_partitions_count
    commonEnvironmentVariables = local.final_logscale_configuration_vars
    extraHumioVolumeMounts     = local.extraHumioVolumeMounts_filtered
    extraVolumes               = local.extraVolumes_filtered
    hostname                   = local.logscale_hostname
    image                      = local.logscale_image
    imagePullSecrets           = local.imagePullSecrets
    license                    = local.logscale_license_ref
    nodeCount                  = local.logscale_digest_node_count
    resources                  = local.logscale_digest_resources_spec
    targetReplicationFactor    = local.target_replication_factor
    updateStrategy             = var.logscale_update_strategy
    tls                        = local.logscale_tls_spec
    nodePools                  = local.selected_node_pools
  }

  # Merge the specs
  final_spec = merge(local.base_humio_cluster_spec, var.extra_humio_cluster_spec)

}

# Define the humio cluster based on our given inputs
resource "kubernetes_manifest" "humio_cluster" {
  manifest = {
    apiVersion = local.humiocluster_manifest_api_version
    kind       = local.humiocluster_manifest_kind

    metadata = {
      name      = var.name_prefix
      namespace = local.logscale_kubernetes_namespace
    }

    spec = local.final_spec
  }

  depends_on = [data.kubernetes_resources.check_humio_cluster_crd]

  computed_fields = ["metadata.labels"]

  field_manager {
    name            = "tfapply"
    force_conflicts = true
  }
}
