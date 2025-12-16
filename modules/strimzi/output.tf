output "kafka-connection-string" {
    value = "${var.name_prefix}-strimzi-kafka-kafka-bootstrap.${local.kubernetes_namespace}.svc.cluster.local:9093"
}