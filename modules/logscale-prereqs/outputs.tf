output "k8s_secret_static_user_logins" {
    value = kubernetes_secret_v1.static_user_logins.metadata[0].name
}

output "k8s_secret_logscale_license" {
    value = kubernetes_secret_v1.logscale_license.metadata[0].name
}
