locals {
  # Render a template of available cluster sizes
  cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))

  cluster_size_rendered = {
    for key in keys(local.cluster_size_template) :
    key => local.cluster_size_template[key]
  }

  node_group_definitions = merge(local.cluster_size_rendered[var.logscale_cluster_size], var.node_group_definitions)

  lvm_target_node_labels = distinct(concat(
    ["logscale-digest"],
    lookup(local.node_group_definitions, "kafka_broker_data_storage_class", "topolvm-provisioner") == "topolvm-provisioner" ? ["strimzi"] : [],
    lookup(local.node_group_definitions, "logscale_ui_data_disk_type", "topolvm-provisioner") == "topolvm-provisioner" ? ["logscale-ui"] : [],
    lookup(local.node_group_definitions, "logscale_ingest_data_disk_type", "topolvm-provisioner") == "topolvm-provisioner" ? ["logscale-ingest"] : []
  ))

  # DEPRECATED: Previous non-deterministic approach using random_string
  # resource_name_prefix = "z${random_string.name-modifier.result}-${var.resource_name_prefix}"

  # Use deterministic naming: prefer k8s_cluster_context (derived from cluster_name),
  # fall back to resource_name_prefix if k8s_cluster_context is not provided
  resource_name_prefix = coalesce(var.k8s_cluster_context, var.resource_name_prefix)

  humio_operator_replica_count = var.dr == "standby" ? 0 : 1
}