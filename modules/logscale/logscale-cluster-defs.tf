# This locals block is largely here to move repeated configurations out of the HumioCluster 
# kubernetes manifest definitions to a single place so that updates are applied consistently
# to all architecture types.
# Doc ref: https://github.com/humio/humio-operator/blob/master/docs/api.md#humiocluster

locals {
  # The namespace that will be used by all resources created from these manifests
  logscale_kubernetes_namespace = "${var.k8s_namespace_prefix}"

  # The desired number of digest partitions
  digest_partitions_count = 840

  # Hostname is the public hostname used by clients to access logscale
  logscale_hostname = "${var.logscale_public_fqdn}"

  # This is the image to use for installing logscale
  logscale_image = var.logscale_image != null ? var.logscale_image : "humio/humio-core:${var.logscale_image_version}"
  imagePullSecrets = var.logscale_image != null ? [{ name = var.image_pull_secret }] : null

  # The kubernetes secret containing the strimzi cert for our nodes to connect to the cluster
  kafka_truststore_secret_name = "${var.name_prefix}-strimzi-kafka-cluster-ca-cert"

  # Enable/Disable TLS for logscale intracluster communications
  logscale_tls_spec = {
      enabled               = true
      # extraHostnames      = [string, string, ...]
      #caSecretName          = "${var.name_prefix}-ca-keypair"
    }

  # Environment variables to apply to all humiocluster pods
  commonEnvironmentVariables = [
      {
        name = "KAFKA_COMMON_SECURITY_PROTOCOL"
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
        name = "PUBLIC_URL"
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
        name = "KAFKA_COMMON_SSL_TRUSTSTORE_TYPE"
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
        name = "KAFKA_COMMON_SSL_TRUSTSTORE_LOCATION"
        value = "/tmp/kafka/ca.p12"
      },
    ]
  

  # If this is a bring-your-own-kafka situation, we need to remove these settings from the above list
  kafka_env_configs_remove = [ "KAFKA_COMMON_SSL_TRUSTSTORE_TYPE", "KAFKA_COMMON_SSL_TRUSTSTORE_PASSWORD", "KAFKA_COMMON_SSL_TRUSTSTORE_LOCATION" ]

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
                  accessModes = [ "ReadWriteOnce" ]
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
                key       = "kubernetes.io/arch"
                operator  = "In"
                values    = [ "amd64" ]
              },
              {
                key       = "kubernetes.io/os"
                operator  = "In"
                values    = [ "linux" ]
              },
              {
                key       = "k8s-app"
                operator  = "In"
                values    = [ "logscale-digest" ]
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
                values = [ "humio" ]
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
        cpu       = var.logscale_digest_resources["limits"]["cpu"],
        memory    = var.logscale_digest_resources["limits"]["memory"]
      },
      requests = {
        cpu       = var.logscale_digest_resources["requests"]["cpu"]
        memory    = var.logscale_digest_resources["requests"]["memory"]
      }
    }
  
  # The number of digest pods we will run
  logscale_digest_node_count = var.logscale_digest_pod_count

  # TargetReplicationFactor is the desired number of replicas of both storage and ingest partitions
  target_replication_factor = var.target_replication_factor

  # HumioCluster kubernetes manifest settings
  humiocluster_manifest_api_version = "core.humio.com/v1alpha1"
  humiocluster_manifest_kind = "HumioCluster"

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
                    key         = "kubernetes.io/arch"
                    operator    = "In"
                    values      = [ "amd64" ]
                  },
                  {
                    key         = "kubernetes.io/os"
                    operator    = "In"
                    values      = [ "linux" ]
                  },
                  {
                    key         = "k8s-app"
                    operator    = "In"
                    values      = [ "logscale-ui" ]
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
                    key         = "app.kubernetes.io/name"
                    operator    = "In"
                    values      = [ "humio" ]
                  }
                ]
              }
              topologyKey       = "kubernetes.io/hostname"
            }
          ]
        }
      }

      dataVolumePersistentVolumeClaimSpecTemplate = {
          accessModes           = [ "ReadWriteOnce" ]
          resources = {
            requests = {
              storage           = var.logscale_ui_data_disk_size
            }
          }
          storageClassName      = var.kube_storage_class_for_logscale_ui
        }

      environmentVariables = [
        {
          name                  = "NODE_ROLES"
          value                 = "httponly"
        },
        {
          name                  = "INITIAL_DISABLED_NODE_TASK"
          value                 = "digest,storage"
        }
      ]

      extraHumioVolumeMounts    = local.extraHumioVolumeMounts_filtered
      extraVolumes              = local.extraVolumes_filtered // ISSUE
      image                     = local.logscale_image

      imagePullSecrets          = local.imagePullSecrets 
      
      nodeCount                 = var.logscale_ui_pod_count
      resources = {
        limits = {
          cpu                   = var.logscale_ui_resources["limits"]["cpu"],
          memory                = var.logscale_ui_resources["limits"]["memory"]
        }
        requests = {
          cpu                   = var.logscale_ui_resources["requests"]["cpu"]
          memory                = var.logscale_ui_resources["requests"]["memory"]
        }
      }
      updateStrategy            = var.logscale_update_strategy
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
                    key         = "kubernetes.io/arch"
                    operator    = "In"
                    values      = [ "amd64" ]
                  },
                  {
                    key         = "kubernetes.io/os"
                    operator    = "In"
                    values      = [ "linux" ]
                  },
                  {
                    key         = "k8s-app"
                    operator    = "In"
                    values      = [ "logscale-ingest" ]
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
                    key         = "app.kubernetes.io/name"
                    operator    = "In"
                    values      = [ "humio" ]
                  }
                ]
              }
              topologyKey       = "kubernetes.io/hostname"
            }
          ]
        }
      }

      dataVolumePersistentVolumeClaimSpecTemplate = {
        accessModes             = [ "ReadWriteOnce" ]
        resources = {
          requests = {
            storage             = var.logscale_ingest_data_disk_size
          }
        }
        storageClassName        = var.kube_storage_class_for_logscale_ingest
      }

      environmentVariables = [
        {
          name                  = "NODE_ROLES"
          value                 = "ingestonly"
        },
        {
          name                  = "INITIAL_DISABLED_NODE_TASK"
          value                 = "digest,query,storage"
        }
      ]
      extraHumioVolumeMounts    = local.extraHumioVolumeMounts_filtered
      extraVolumes              = local.extraVolumes_filtered
      image                     = local.logscale_image
      imagePullSecrets          = local.imagePullSecrets 

      nodeCount                 = var.logscale_ingest_pod_count
      resources = {
        limits = {
          cpu                   = var.logscale_ingest_resources["limits"]["cpu"],
          memory                = var.logscale_ingest_resources["limits"]["memory"]
        }
        requests = {
          cpu                   = var.logscale_ingest_resources["requests"]["cpu"]
          memory                = var.logscale_ingest_resources["requests"]["memory"]
        }
      }
      updateStrategy            = var.logscale_update_strategy
    }
  }

  node_pool_mapping = {
    "basic"           = null
    "ingress"         = null
    "dedicated-ui"    = [ local.ui_node_pool_spec ]
    "advanced"        = [ local.ui_node_pool_spec, local.ingest_node_pool_spec ]
  }

  ##### FILTERS #####
  # These are here to filter out the kafka related settings when strimzi is not used as the kafka source
  extraHumioVolumeMounts_filtered = var.provision_kafka_servers ? concat(local.extraHumioVolumeMounts, local.extraKafkaTrustStoreVolumeMounts) : length(local.extraHumioVolumeMounts) > 0 ? local.extraHumioVolumeMounts : null
  extraVolumes_filtered = var.provision_kafka_servers ? concat(local.extraHumioVolumes, local.extraKafkaTrustStoreVolume) : length(local.extraHumioVolumes) > 0 ? local.extraHumioVolumes : null
  # extraVolumes_filtered = local.extraHumioVolumes
  commonEnvironmentVariables_filtered = [ for m in local.commonEnvironmentVariables : m if (!(contains(local.kafka_env_configs_remove, m.name)) || var.provision_kafka_servers) ]
  
  # This is here to merge together user provided variables with environment variables set above
  cevmap = { for e in local.commonEnvironmentVariables_filtered : e.name => e }
  uevmap = { for e in var.user_logscale_envvars : e.name => e }

  # This will merge the locally defined environment settings with user defined settings giving preference to user settings
  mergedmap = merge(local.cevmap, local.uevmap)

  # And this will get a final list of configuration settings allowing for normal values and valueFrom
  final_logscale_configuration_vars = [ 
    for name in keys(local.mergedmap) : merge(
      { name = name },
      lookup(local.mergedmap[name], "value", null) != null ? { value = local.mergedmap[name].value } : {},
      lookup(local.mergedmap[name], "valueFrom", null) != null ? { valueFrom = local.mergedmap[name].valueFrom } : {}
    )
   ]
  
  
  ###################

  selected_node_pools = lookup(local.node_pool_mapping, var.logscale_cluster_type, "basic")
  
  base_humio_cluster_spec = {
    affinity                        = local.digest_node_affinity_def
    dataVolumeSource                = local.digest_data_volume_source_def
    digestPartitionsCount           = local.digest_partitions_count
    commonEnvironmentVariables      = local.final_logscale_configuration_vars
    extraHumioVolumeMounts          = local.extraHumioVolumeMounts_filtered
    extraVolumes                    = local.extraVolumes_filtered
    hostname                        = local.logscale_hostname
    image                           = local.logscale_image
    imagePullSecrets                = local.imagePullSecrets 
    license                         = local.logscale_license_ref
    nodeCount                       = local.logscale_digest_node_count
    resources                       = local.logscale_digest_resources_spec
    targetReplicationFactor         = local.target_replication_factor
    updateStrategy                  = var.logscale_update_strategy
    tls                             = local.logscale_tls_spec

    nodePools                       = local.selected_node_pools
  }

  # Merge the specs
  final_spec = merge(local.base_humio_cluster_spec, var.extra_humio_cluster_spec)
  
}

# Define the humio cluster based on our given inputs
resource "kubernetes_manifest" "humio_cluster" {
  manifest = {
    apiVersion                        = local.humiocluster_manifest_api_version
    kind                              = local.humiocluster_manifest_kind

    metadata = {
      name                            = var.name_prefix
      namespace                       = local.logscale_kubernetes_namespace
    }

    spec = local.final_spec
  }

  depends_on                          = [ data.kubernetes_resources.check_humio_cluster_crd ]

  computed_fields                     = [ "metadata.labels" ]

  field_manager {
    name                              = "tfapply"
    force_conflicts                   = true
  }
}
