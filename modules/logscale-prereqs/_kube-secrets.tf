# Create kubernetes secrets used by logscale
resource "random_password" "single_user_password" {
  length  = 48
  special = false

  keepers = {
    "random-value" = var.password_rotation_arbitrary_value
  }
}

# Create a secret for the user list
resource "kubernetes_secret_v1" "static_user_logins" {
  metadata {
    name      = "${var.name_prefix}-static-users"
    namespace = "${var.k8s_namespace_prefix}"
  }
  data = {
    users = "admin:${random_password.single_user_password.result}"
  }

  depends_on = [
    kubernetes_manifest.logscale_ns
  ]
}

resource "kubernetes_secret_v1" "logscale_license" {
  metadata {
    name      = "${var.name_prefix}-license"
    namespace = "${var.k8s_namespace_prefix}"
  }
  data = {
    humio-license-key = var.logscale_license
  }

  depends_on = [
    kubernetes_manifest.logscale_ns
  ]
}

# This is here to store the logscale_public_fqdn value for use with the ingest-testing module later. 
resource "kubernetes_secret_v1" "logscale_endpoint" {
  metadata {
    name      = "${var.name_prefix}-logscale-endpoint"
    namespace = "${var.k8s_namespace_prefix}"
  }
  data = {
    value = var.logscale_public_fqdn
  }

  depends_on = [
    kubernetes_manifest.logscale_ns
  ]
}

# The encryption key given with AZURE_STORAGE_ENCRYPTION_KEY can be any UTF-8 string and will
# be used to encrypt the data stored within the bucket. The suggested value is 64 or more random ASCII characters.
# This encryption is applied prior to bucket upload.
resource "random_password" "encryption_password" {
  length  = 64
  special = false
}

resource "kubernetes_secret_v1" "storage_encryption_key" {
  metadata {
    name      = "${var.name_prefix}-storage-encryption"
    namespace = "${var.k8s_namespace_prefix}"
  }
  data = {
    storage-encryption-key = random_password.encryption_password.result
  }

  depends_on = [
    kubernetes_manifest.logscale_ns
  ]
}
