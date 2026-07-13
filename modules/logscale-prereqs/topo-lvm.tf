# Wait for cert_manager
resource "time_sleep" "wait_for_cert_manager" {
  count           = var.use_topo_lvm ? 1 : 0
  depends_on      = [helm_release.cert_manager]
  create_duration = "1m"
}

# Topo LVM Controller Install
resource "helm_release" "topo_lvm_sc" {
  count = var.use_topo_lvm ? 1 : 0
  name  = "${var.name_prefix}-topo-lvm"

  repository       = "https://topolvm.github.io/topolvm"
  chart            = "topolvm"
  namespace        = kubernetes_namespace_v1.logscale-topo.metadata[0].name
  create_namespace = false
  wait             = "false"
  version          = var.topo_lvm_chart_version

  values = [
    templatefile(
      "${path.module}/helm_values/topo_lvm_sc.yaml.tpl",
      {
        node_types            = var.lvm_target_node_labels
        lvmd_extra_host_paths = var.lvm_extra_host_paths
        topo_lvm_disk_pattern = var.topo_lvm_disk_pattern
      }
    )
  ]

  set {
    name  = "controller.replicaCount"
    value = var.topo_lvm_controller_replicas
  }

  depends_on = [
    time_sleep.wait_for_cert_manager
  ]
}
