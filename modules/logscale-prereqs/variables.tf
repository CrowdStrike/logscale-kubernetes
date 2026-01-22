variable "logscale_cluster_type" {
  description = "Logscale cluster type"
  type        = string
}

variable "lvm_extra_host_paths" {
  description = "Extra host paths to mount in the LVM setup daemonset. Cloud modules can specify cloud-specific paths here."
  type = list(object({
    name       = string
    host_path  = string
    mount_path = string
    type       = optional(string, "DirectoryOrCreate")
  }))
  default = []
}

variable "name_prefix" {
  type        = string
  description = "Identifier attached to named resources to help them stand out."
}

variable "cert_issuer_kind" {
  description = "Certificates issuer kind for the Logscale cluster."
  type        = string
}

variable "cert_issuer_name" {
  description = "Certificates issuer name for the Logscale Cluster"
  type        = string
}

variable "cert_issuer_email" {
  description = "Certificates issuer email for the Logscale Cluster"
  type        = string
}

variable "cert_issuer_private_key" {
  description = "Certificates issuer private key for the Logscale Cluster"
  type        = string
}

variable "cert_ca_server" {
  description = "Certificate Authority Server."
  type        = string
}

variable "nginx_ingress_sets" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "cm_repo" {
  description = "The cert-manager repository."
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cm_version" {
  description = "The cert-manager helm chart version"
  type        = string

}

variable "topo_lvm_chart_version" {
  type        = string
  description = "TopoLVM Chart version to use for installation."
}

variable "k8s_namespace_prefix" {
  description = "Multiple namespaces will be created to contain resources using this prefix."
  type        = string
  default     = "log"
}

variable "existing_logscale_namespace" {
  description = "When true, check if the primary Logscale namespace already exists and reuse it instead of creating a duplicate."
  type        = bool
  default     = true
}

variable "use_topo_lvm" {
  default     = true
  type        = bool
  description = "Use TopoLVM for volume group management"
}

variable "topo_lvm_disk_pattern" {
  description = "The pattern used by ls (ls /dev/<topo_lvm_disk_pattern>) to find the disks to add to the LVM volume group"
  type        = string
  default     = "nvme*n*"
}

variable "topo_lvm_controller_replicas" {
  description = "Number of replicas for the topo_lvm controller"
  type        = number
  default     = 2
}

variable "lvm_target_node_labels" {
  description = "List of node labels (k8s-app values) where LVM preparation should run. Passed from the parent module."
  type        = list(string)
}

variable "use_custom_certificate" {
  default     = false
  type        = bool
  description = "Use a custom provided certificate on the frontend instead of Let's Encrypt?"
}

variable "custom_tls_certificate_keyvault_entry" {
  type        = string
  description = "The keyvault entry containing the TLS certificate"
  default     = null
}

variable "password_rotation_arbitrary_value" {
  type        = string
  description = "This can be any old value and does not factor into password generation. When changed, it will result in a new password being generated and saved to kubernetes secrets."
  default     = "defaultstring"
}

variable "logscale_license" {
  type        = string
  description = "Your logscale license."
}

/* These variables control the nginx-ingress controller */
variable "logscale_ingress_pod_count" {
  type        = number
  description = "The number of ingress pods to start with."
}
variable "logscale_ingress_min_pod_count" {
  type        = number
  description = "The minimum number of ingress pods."
}
variable "logscale_ingress_max_pod_count" {
  type        = number
  description = "The maximum number of ingress pods."
}
variable "logscale_ingress_resources" {
  type        = map(any)
  description = "The resource requests and limits for cpu and memory to apply ingress pods formatted in a json map. Example: {\"limits\": {\"cpu\": 2, \"memory\": \"2Gi\"}, \"requests\": {\"cpu\": 2, \"memory\": \"2Gi\"}}"
}
variable "logscale_ingress_data_disk_size" {
  description = "The size of the data disk to provision for each ingress pod. (i.e. 20Gi)"
  type        = string
}

variable "logscale_public_fqdn" {
  type        = string
  description = "The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt."
}

variable "nginx_ingress_helm_chart_version" {
  description = "The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping."
  type        = string
}

variable "deploy_nginx_ingress" {
  description = "Deploy a nginx ingress controller"
  type        = bool
  default     = true
}

variable "primary_encryption_key_value" {
  description = "Primary cluster's storage encryption key value (for standby clusters from remote state). If provided, uses this value instead of generating a new one."
  type        = string
  default     = null
  sensitive   = true
}

variable "skip_cluster_issuer" {
  description = "Skip creation of the Let's Encrypt ClusterIssuer. Set to true when using DNS-01 solver managed externally (e.g., OCI DNS webhook)."
  type        = bool
  default     = false
}

