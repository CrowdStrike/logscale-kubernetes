output "cluster_name_prefix" {
  description = "The cluster name prefix used for resource naming"
  value       = local.resource_name_prefix
}

output "storage_encryption_key_value" {
  description = "Storage encryption key value (for DR standby clusters)"
  value       = module.logscale-prereqs.storage_encryption_key_value
  sensitive   = true
}

output "prereqs_ready_id" {
  description = "Opaque ID that is only available after prereqs are applied; used for dependency ordering in wrappers."
  value       = null_resource.prereqs_ready.id
}
