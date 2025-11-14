variable "name_prefix" {
  type = string
  description = "Identifier attached to named resources to help them stand out."
}

variable "strimzi_operator_chart_version" {
  type = string
  description = "Helm release chart version for Strimzi."
}

variable "strimzi_operator_repo" {
  type = string
  description = "Strimzi operator repo."
}

variable "kafka_broker_pod_replica_count" {
  type = number
  description = "The number of pods to run in this kafka cluster."
}

variable "kafka_broker_resources" {
  type = map
  description = "The resource requests and limits for cpu and memory to apply to the pods formatted in a json map. Example: {\"limits\": {\"cpu\": 6, \"memory\": \"48Gi\"}, \"requests\": {\"cpu\": 6, \"memory\": \"48Gi\"}}"
}

variable "kafka_broker_data_disk_size" {
  description = "The size of the data disk to provision for each kafka broker. (i.e. 2048Gi)"
  type = string
}

variable "kube_storage_class_for_kafka" {
  description = "In AKS, we expect to use the 'default' storage class for managed SSD but this could be any storage class you have configured in kubernetes."
  default = "default"
  type = string
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
}

variable "num_kafka_volumes" {
  description       = "Kafka brokers will have at least 1 volume. This specifies additional volumes to increase throughput by spreading partitions across multiple disks."
  type              = number
  default           = 1
}