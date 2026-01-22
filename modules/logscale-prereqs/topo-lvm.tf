# This resource sets up a small container that provisions disk. This is done as a daemonset to guarantee execution
# on every target node (NVME-backed) nodes. The pod restarts on failure.
resource "kubernetes_daemon_set_v1" "lvm-setup" {
  count = var.use_topo_lvm ? 1 : 0
  metadata {
    name      = "${var.name_prefix}-lvm-setup"
    namespace = kubernetes_namespace_v1.logscale-topo.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        name = "lvm-setup"
      }
    }

    template {
      metadata {
        labels = {
          name = "lvm-setup"
        }
      }
      spec {
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "k8s-app"
                  operator = "In"
                  values   = var.lvm_target_node_labels
                }
              }
            }
          }
        }

        automount_service_account_token = false

        container {
          name  = "lvm-setup"
          image = "debian:bookworm-slim"
          command = [
            "/bin/bash",
            "-c",
            <<-EOT
              apt-get update && apt-get install -y lvm2 parted fdisk

            echo "Scanning for available disks..."
            available_disks=""
            
            # Check for NVMe disks first
            for disk in $(ls /dev/${var.topo_lvm_disk_pattern} 2>/dev/null || true); do
              echo "Found NVMe disk: $disk"
              if pvcreate $disk 2>/dev/null; then
                echo "SUCCESS: Disk $disk initialized"
                available_disks="$available_disks $disk"
              fi
            done
            
            # If no NVMe, check for /dev/sdb (common temp disk)
            # NOTE: /dev/sdb cannot be reclaimed from container - it's mounted before K8s starts
            # This would require a custom script extension or cloud-init to work properly
            # if [ -z "$available_disks" ] && [ -b /dev/sdb ]; then
            #   echo "Found /dev/sdb, but cannot unmount from container context"
            # fi

            echo "Available disks: $available_disks"

            if [ -n "$available_disks" ]; then
              VG_NAME="nvme-vg"
              # Use ssd-vg if using /dev/sdb
              if echo "$available_disks" | grep -q "sdb"; then
                VG_NAME="ssd-vg"
              fi
              
              echo "Creating volume group $VG_NAME..."
              vgcreate $VG_NAME $available_disks || true
              echo "SUCCESS: Volume group $VG_NAME created"
              vgs $VG_NAME
            else
              echo "ERROR: No suitable disks found"
            fi

            echo "LVM setup completed"
            sleep infinity
            EOT
          ]

          security_context {
            # privileged mode is necessary due to this container needing to modify
            # disks for the underlying node.
            privileged = true

            seccomp_profile {
              type = "RuntimeDefault"
            }
          }

          resources {
            limits = {
              memory = "200Mi"
              cpu    = "100m"
            }
            requests = {
              memory = "200Mi"
              cpu    = "100m"
            }
          }

          dynamic "volume_mount" {
            for_each = var.lvm_extra_host_paths
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
            }
          }
        }

        dynamic "volume" {
          for_each = var.lvm_extra_host_paths
          content {
            name = volume.value.name
            host_path {
              path = volume.value.host_path
              type = volume.value.type
            }
          }
        }

        volume {
          name = "host-root"
          host_path {
            path = "/"
          }
        }
      }
    }
  }
}

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
        node_types = var.lvm_target_node_labels
      }
    )
  ]

  set {
    name  = "controller.replicaCount"
    value = var.topo_lvm_controller_replicas
  }

  depends_on = [
    kubernetes_daemon_set_v1.lvm-setup,
    time_sleep.wait_for_cert_manager
  ]
}
