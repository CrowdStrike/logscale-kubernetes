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
    namespace = var.k8s_namespace_prefix
  }
  data = {
    users = "admin:${random_password.single_user_password.result}"
  }

  depends_on = [null_resource.logscale_ns]
}

resource "kubernetes_secret_v1" "logscale_license" {
  metadata {
    name      = "${var.name_prefix}-license"
    namespace = var.k8s_namespace_prefix
  }
  data = {
    humio-license-key = var.logscale_license
  }

  depends_on = [null_resource.logscale_ns]
}

# This is here to store the logscale_public_fqdn value for use with the ingest-testing module later. 
resource "kubernetes_secret_v1" "logscale_endpoint" {
  metadata {
    name      = "${var.name_prefix}-logscale-endpoint"
    namespace = var.k8s_namespace_prefix
  }
  data = {
    value = var.logscale_public_fqdn
  }

  depends_on = [null_resource.logscale_ns]
}

# The encryption key given with AZURE_STORAGE_ENCRYPTION_KEY can be any UTF-8 string and will
# be used to encrypt the data stored within the bucket. The suggested value is 64 or more random ASCII characters.
# This encryption is applied prior to bucket upload.
# For standby DR clusters, if primary_encryption_key_value is provided, it will be used instead of generating a new one.
resource "random_password" "encryption_password" {
  count   = var.primary_encryption_key_value == null ? 1 : 0
  length  = 64
  special = false
}

locals {
  # Use primary's key if provided (standby), otherwise use generated key (active/primary)
  effective_encryption_key = var.primary_encryption_key_value != null ? var.primary_encryption_key_value : random_password.encryption_password[0].result
}

resource "kubernetes_secret" "storage_encryption_key" {
  metadata {
    name      = "${var.name_prefix}-storage-encryption"
    namespace = var.k8s_namespace_prefix
  }
  data = {
    storage-encryption-key = local.effective_encryption_key
  }

  depends_on = [null_resource.logscale_ns]
}
