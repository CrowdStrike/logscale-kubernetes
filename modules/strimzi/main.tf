/**
 * ## Module: kubernetes/strimzi
 * This module installs Strimzi Kafka in kraft mode for use with the logscale ingestion pipeline. 
 * 
 */

# Convert the given number of broker pods into a controller/broker split and account for the smallest 
# architecture of 3 nodes
locals {
  possible_controller_counts = [for c in [3, 5, 7] : c if c < var.kafka_broker_pod_replica_count]
  controller_count           = var.kafka_broker_pod_replica_count <= 3 ? 3 : max(local.possible_controller_counts...)
  broker_count               = var.kafka_broker_pod_replica_count <= 3 ? 0 : var.kafka_broker_pod_replica_count - local.controller_count

  kubernetes_namespace = var.k8s_namespace_prefix
  io_threads           = var.num_kafka_volumes * 2
}

# Helm for Strimzi
resource "helm_release" "strimzi_operator" {
  name       = "strimzi-operator"
  repository = var.strimzi_operator_repo
  chart      = "strimzi-kafka-operator"
  namespace  = local.kubernetes_namespace
  wait       = "false"
  version    = var.strimzi_operator_chart_version
}

# Rebalance setup for Strimzi Kafka
resource "kubernetes_manifest" "kafka_cluster_rebalance" {
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "KafkaRebalance"
    "metadata" = {
      "labels" = {
        "strimzi.io/cluster" = "${var.name_prefix}-strimzi-kafka"
      }
      "name"      = "${var.name_prefix}-strimzi-kafka-rebalance"
      "namespace" = local.kubernetes_namespace
    }
    "spec" = {
      "goals" = [
        "NetworkInboundCapacityGoal",
        "DiskCapacityGoal",
        "RackAwareGoal",
        "NetworkOutboundCapacityGoal",
        "CpuCapacityGoal",
        "ReplicaCapacityGoal",
      ]
    }
  }
  depends_on = [
    helm_release.strimzi_operator,
  ]
}

# Kafka cluster specificiation - defines the kafka cluster configuration
resource "kubernetes_manifest" "kafka_cluster" {
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "Kafka"
    "metadata" = {
      "name"      = "${var.name_prefix}-strimzi-kafka"
      "namespace" = local.kubernetes_namespace
      "annotations" = {
        "strimzi.io/node-pools" = "enabled"
        "strimzi.io/kraft"      = "enabled"
      }
    }
    "spec" = {
      "kafka" = {
        "version"         = "4.0.0",
        "metadataVersion" = "4.0-IV0"
        "config" = {
          "auto.create.topics.enable"                = true
          "default.replication.factor"               = 3
          "min.insync.replicas"                      = 2
          "offsets.topic.replication.factor"         = 2
          "replica.selector.class"                   = "org.apache.kafka.common.replica.RackAwareReplicaSelector"
          "transaction.state.log.min.isr"            = 1
          "transaction.state.log.replication.factor" = 2
          "ssl.enabled.protocols"                    = "TLSv1.3, TLSv1.2"
          "ssl.protocol"                             = "TLSv1.3"
          "ssl.client.auth"                          = "required"
          "num.io.threads"                           = "${local.io_threads}"
        }
        "listeners" = [
          {
            "name" = "tls"
            "port" = 9093
            "tls"  = true
            "type" = "internal"
          },
        ]
        "rack" = {
          "topologyKey" = "topology.kubernetes.io/zone"
        }

        "resources" = {
          "limits" = {
            "cpu"    = var.kafka_broker_resources["limits"]["cpu"],
            "memory" = var.kafka_broker_resources["limits"]["memory"]
          }
          "requests" = {
            "cpu"    = var.kafka_broker_resources["requests"]["cpu"],
            "memory" = var.kafka_broker_resources["requests"]["memory"]
          }
        }

        "template" = {
          "pod" = {
            "affinity" = {
              "nodeAffinity" = {
                "requiredDuringSchedulingIgnoredDuringExecution" = {
                  "nodeSelectorTerms" = [
                    {
                      "matchExpressions" = [
                        {
                          "key"      = "k8s-app"
                          "operator" = "In"
                          "values" = [
                            "strimzi",
                          ]
                        },
                      ]
                    },
                  ]
                }
              }
              "podAntiAffinity" = {
                "requiredDuringSchedulingIgnoredDuringExecution" = [
                  {
                    "labelSelector" = {
                      "matchExpressions" = [
                        {
                          "key"      = "app.kubernetes.io/name"
                          "operator" = "In"
                          "values" = [
                            "logscale", "system"
                          ]
                        },
                      ]
                    }
                    "topologyKey" = "kubernetes.io/hostname"
                  },
                ]
              }
            }
          }
        }

      }
    }
  }

  depends_on = [
    helm_release.strimzi_operator, kubernetes_manifest.kafka-node-pool
  ]

}

# Node pools for the kafka cluster
# Note: Strimzi pod names are generated as <kafka-cluster-name>-<nodepool-name>-<index>
# DNS labels are limited to 63 chars, so we use short static pool names to avoid exceeding the limit
# Example: zfeo94-dr-secondary-strimzi-kafka-dual-role-0 (47 chars - OK)
# vs: zfeo94-dr-secondary-strimzi-kafka-zfeo94-dr-secondary-dual-role-0 (65 chars - FAILS)
resource "kubernetes_manifest" "kafka-node-pool" {
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "KafkaNodePool"
    "metadata" = {
      "name"      = "dual-role"
      "namespace" = local.kubernetes_namespace
      "labels" = {
        "strimzi.io/cluster" : "${var.name_prefix}-strimzi-kafka"
      }
    }
    "spec" = {
      "replicas" = local.controller_count
      "roles"    = ["controller", "broker"]


      storage = {
        type = "jbod"
        volumes = concat([
          # Always have at least one mount
          {
            id            = 0
            type          = "persistent-claim"
            deleteClaim   = true
            size          = var.kafka_broker_data_disk_size
            type          = "persistent-claim"
            class         = var.kube_storage_class_for_kafka
            kraftMetadata = "shared"
          }
          ], [
          # Additional mounts are created to increase throughput per host
          for idx in range(1, var.num_kafka_volumes) : {
            id          = idx + 1
            type        = "persistent-claim"
            deleteClaim = true
            size        = var.kafka_broker_data_disk_size
            type        = "persistent-claim"
            class       = var.kube_storage_class_for_kafka
          }
        ])
      }

    }
  }

  depends_on = [helm_release.strimzi_operator]
}

resource "kubernetes_manifest" "kafka-node-pool-extrabrokers" {
  count = local.broker_count > 0 ? 1 : 0
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "KafkaNodePool"
    "metadata" = {
      "name"      = "extra-brokers"
      "namespace" = local.kubernetes_namespace
      "labels" = {
        "strimzi.io/cluster" : "${var.name_prefix}-strimzi-kafka"
      }
    }
    "spec" = {
      "replicas" = local.broker_count
      "roles"    = ["broker"]

      storage = {
        type = "jbod"
        volumes = concat([
          # Always have at least one mount
          {
            id            = 0
            type          = "persistent-claim"
            deleteClaim   = false
            size          = var.kafka_broker_data_disk_size
            type          = "persistent-claim"
            class         = var.kube_storage_class_for_kafka
            kraftMetadata = "shared"
          }
          ], [
          # Additional mounts are created to increase throughput per host
          for idx in range(1, var.num_kafka_volumes + 1) : {
            id          = idx
            type        = "persistent-claim"
            deleteClaim = false
            size        = var.kafka_broker_data_disk_size
            type        = "persistent-claim"
            class       = var.kube_storage_class_for_kafka
          }
        ])
      }


    }
  }
  depends_on = [helm_release.strimzi_operator]
}

