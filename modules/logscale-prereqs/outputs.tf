output "k8s_secret_static_user_logins" {
  value = kubernetes_secret_v1.static_user_logins.metadata[0].name
}

output "k8s_secret_logscale_license" {
  value = kubernetes_secret_v1.logscale_license.metadata[0].name
}

output "storage_encryption_key_value" {
  description = "The storage encryption key value (either generated or from primary)"
  value       = local.effective_encryption_key
  sensitive   = true
}

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = kubernetes_namespace_v1.cert_manager[0].metadata[0].name
}

output "cert_manager_ready" {
  description = "Marker output that indicates cert-manager Helm release is complete. Use this for depends_on in modules that need cert-manager."
  value       = try(helm_release.cert_manager[0].status, "deployed")
}
