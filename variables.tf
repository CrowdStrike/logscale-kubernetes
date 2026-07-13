variable "resource_name_prefix" {
  type        = string
  default     = "log"
  description = "Identifier attached to named resources to help them stand out. Must be 63 or fewer characters which can include lower case, numbers, and hyphens."

  validation {
    condition     = length(var.resource_name_prefix) <= 63 && can(regex("^[a-z0-9-]*$", var.resource_name_prefix))
    error_message = "The resource_name_prefix is invalid."
  }
}

variable "k8s_cluster_context" {
  type        = string
  description = "Name of the kubernetes cluster"
}

variable "logscale_public_fqdn" {
  type        = string
  description = "The public FQDN of the LogScale cluster"
}

variable "tags" {
  type        = map(any)
  description = "A map of tags to apply to all created resources."
  default     = {}
}

variable "logscale_cluster_type" {
  description = "Logscale cluster type"
  type        = string

  validation {
    condition     = contains(["basic", "ingress", "dedicated-ui", "advanced"], var.logscale_cluster_type)
    error_message = "logscale_cluster_type must be one of: basic, ingress, or advanced"
  }
}

variable "cloud_provider" {
  description = "Cloud provider where the cluster is deployed (e.g., oke, eks, aks, gke)"
  type        = string
  default     = "oke"
}

variable "logscale_cluster_size" {
  description = "Size of the LogScale cluster to build. Reference cluster_size.tpl for definitions."
  type        = string
  default     = "xsmall"

  validation {
    condition     = contains(["xsmall", "small", "medium", "large", "xlarge"], var.logscale_cluster_size)
    error_message = "logscale_cluster_size must be one of: xsmall, small, medium, large, xlarge"
  }
}

variable "node_group_definitions" {
  description = "Node group sizing specification override"
  type        = any
  default     = {}
}

variable "gateway_class_name" {
  description = "Class name of the Gateway API gateway controller"
  type        = string
  default     = "nginx"
}

variable "gateway_api_version" {
  description = "Gateway API helm chart version."
  type        = string
}

variable "gateway_controller_name" {
  description = "The controller name for the Gateway Class (e.g., 'gateway.k8s.aws/alb')"
  type        = string
  default     = "gateway.k8s.aws/alb"
}

variable "gateway_parameters_ref" {
  description = "Parameters reference configuration for the Gateway Class. Map with keys: kind, name, namespace, group (all optional)"
  type = object({
    kind      = optional(string)
    name      = optional(string)
    namespace = optional(string)
    group     = optional(string)
  })
  default = null
}

variable "humio_operator_version" {
  description = "The humio operator controls provisioning of logscale resources within kubernetes."
  type        = string
  default     = "0.32.0"
}

variable "humio_operator_chart_version" {
  description = "This is the version of the helm chart that installs the humio operator version chosen in variable humio_operator_version."
  type        = string
  default     = "0.32.0"
}

variable "cm_repo" {
  description = "The cert-manager repository."
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cm_version" {
  description = "The cert-manager helm chart version"
  type        = string
  default     = "v1.17.1"
}

variable "humio_operator_repo" {
  description = "The humio operator repository."
  type        = string
  default     = "https://humio.github.io/humio-operator"
}


variable "logscale_image_version" {
  description = "The version of logscale to install."
  type        = string
  default     = "1.211.0"
}

variable "logscale_image" {
  description = "This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist."
  type        = string
  default     = null
}

variable "image_pull_secret" {
  description = "The Kubernetes secret containing credentials to access the image repository (e.g., Docker Hub). Required to avoid rate limiting when pulling humio/humio-core images."
  type        = string
  default     = "regcred"
}

variable "logscale_license" {
  description = "Your logscale license data."
  type        = string
}

variable "humio_operator_extra_values" {
  description = "Resource Management for logscale pods"
  type        = map(string)
  default = {
    "operator.resources.limits.cpu"      = "250m"
    "operator.resources.limits.memory"   = "750Mi"
    "operator.resources.requests.cpu"    = "250m"
    "operator.resources.requests.memory" = "750Mi"
  }
}

# TODO: Validate if byo kafka cluster is enabled.
variable "strimzi_operator_chart_version" {
  type        = string
  description = "Helm chart version for installing strimzi."
  default     = "0.45.0"
}

# TODO: Validate if byo kafka cluster is enabled.
variable "strimzi_operator_version" {
  type        = string
  description = "Strimzi operator version for resource definition installation."
  default     = "0.45.0"
}

variable "strimzi_operator_repo" {
  type        = string
  description = "Strimzi operator repo."
  default     = "https://strimzi.io/charts/"
}

variable "cert_issuer_kind" {
  description = "Certificates issuer kind for the Logscale cluster."
  type        = string
  default     = "ClusterIssuer"
}

variable "cert_issuer_name" {
  description = "Certificates issuer name for the Logscale Cluster"
  type        = string
  default     = "letsencrypt-cluster-issuer"
}

variable "cert_issuer_email" {
  description = "Certificates issuer email address used with certificates provisioned in the cluster."
  type        = string
}

variable "cert_issuer_private_key" {
  description = "This is the kubernetes secret where the private key for the certificate issuer will be stored."
  type        = string
  default     = "letsencrypt-cluster-issuer-key"
}

variable "cert_ca_server" {
  description = "Certificate Authority Server."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "password_rotation_arbitrary_value" {
  type        = string
  description = "This will not influence the password generated for logscale but, when modified, will cause the password to be regenerated."
  default     = "defaultstring"
}

variable "provision_kafka_servers" {
  description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
  default     = true
  type        = bool
}

variable "byo_kafka_connection_string" {
  description = "Your own kafka environment connection string."
  default     = ""
  type        = string
}

variable "logscale_namespace" {
  description = "The kubernetes namespace used by strimzi, logscale, and gateway-api."
  type        = string
  default     = "logging"
}

variable "cm_namespace" {
  description = "Kubernetes namespace used by cert-manager."
  type        = string
  default     = "cert-manager"
}

variable "k8s_namespace_prefix" {
  description = "Multiple namespaces will be created to contain resources using this prefix."
  type        = string
  default     = "log"
}

variable "user_logscale_envvars" {
  type = list(object({
    name  = string,
    value = optional(string)
    valueFrom = optional(object({
      secretKeyRef = object({
        name = string
        key  = string
      })
    }))
  }))
  description = "These are environment variables passed into the HumioCluster resource spec definition that will be used for all created logscale instances. Supports string values and kubernetes secret refs. Will override any values defined by default in the configuration."
  default     = []
}

variable "extra_humio_cluster_spec" {
  description = "Extra Humio cluster spec key-values"
  type        = any
  default     = {}
}

variable "humio_service_account_annotations" {
  description = "Annotations to add to Humio service accounts for Workload Identity (GCP) or IRSA (AWS). Applied to all node pools."
  type        = map(string)
  default     = {}
}

variable "extra_gateway_annotations" {
  description = "Extra annotations to add to the Gateway API's gateway resource."
  type        = map(any)
  default     = {}
}

variable "ingress_extra_hostnames" {
  description = "Additional hostnames to add to the ingress (e.g., global failover hostname)"
  type        = list(string)
  default     = []
}

variable "kubeconfig_path" {
  description = "Absolute path to a cluster-specific kubeconfig file. When set, KUBECONFIG is passed as an environment variable to all local-exec provisioners so kubectl targets the correct cluster without mutating ~/.kube/config."
  type        = string
  default     = ""
}

variable "topo_lvm_chart_version" {
  description = "Version of topo lvm to install."
  type        = string
  default     = "15.6.0"
}

variable "use_topo_lvm" {
  default     = true
  type        = bool
  description = "Use TopoLVM for volume group management"
}

variable "pvc_storage_class" {
  description = "Default storage class to use for PVCs"
  type        = string
  default     = "topolvm-provisioner"
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

variable "lvm_extra_host_paths" {
  description = "Extra host paths to mount in the LVM setup daemonset. Cloud modules can specify cloud-specific paths here (e.g., OCI requires /run/lvm and /etc/lvm)."
  type = list(object({
    name       = string
    host_path  = string
    mount_path = string
    type       = optional(string, "DirectoryOrCreate")
  }))
  default = []
}

variable "use_own_certificate_for_ingress" {
  default     = false
  type        = bool
  description = "Set to true if you plan to bring your own certificate for logscale ingest/ui access."
}

variable "enable_pdf_render_service" {
  description = "Enable PDF render service"
  type        = bool
  default     = false
}

variable "pdf_render_service_image" {
  description = "Docker image of the PDF render service"
  type        = string
  default     = ""
}

variable "pdf_render_service_node_count" {
  description = "The replica count of the PDF render service"
  type        = number
  default     = 2
}

variable "logscale_update_strategy" {
  description = "When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdate, 50% maximum unavailable, zone awareness enabled. Reference: https://github.com/humio/humio-operator/blob/master/docs/api.md#humioclusterspecupdatestrategy"
  type        = map(any)
  default = {
    type                = "RollingUpdate"
    enableZoneAwareness = true
    minReadySeconds     = 120
    maxUnavailable      = "50%"
  }
}

variable "deploy_gateway_api" {
  description = "Deploy Gateway API"
  type        = bool
  default     = true
}

variable "dr" {
  description = "Disaster Recovery mode for HumioCluster. Set to 'active' for primary cluster, 'standby' for DR replica, or '' for non-DR cluster."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["active", "standby", ""], var.dr)
    error_message = "The dr variable must be 'active', 'standby', or '' (empty for non-DR)."
  }
}

variable "dr_use_dedicated_routing" {
  description = <<-EOT
    Enable dedicated pool routing (UI/Ingest pods) for DR clusters.

    Default is true - normal pool-specific routing for optimized traffic distribution.

    Set to false ONLY during DR promotion to enable zero-downtime failover:
    - When false: Service selectors use { "app.kubernetes.io/name" = "humio" } to match ALL pods
    - Traffic continues to existing digest pod while UI/Ingest pods scale up

    Two-phase DR promotion workflow:
    1. First apply: Set dr="active" with dr_use_dedicated_routing=false
       - Zero-downtime: traffic goes to digest pod during UI/Ingest scale-up
    2. Second apply: Set dr_use_dedicated_routing=true (or remove the override)
       - Traffic routes to dedicated UI/Ingest pools

    For non-DR clusters (dr=""), this variable is ignored - pool-specific routing is always used.
  EOT
  type        = bool
  default     = true
}

variable "primary_encryption_key_value" {
  description = "Primary cluster's storage encryption key value (for standby clusters from remote state)"
  type        = string
  default     = null
  sensitive   = true
}

variable "skip_cluster_issuer" {
  description = "Skip creation of the Let's Encrypt ClusterIssuer. Set to true when using DNS-01 solver managed externally (e.g., OCI DNS webhook for standby clusters)."
  type        = bool
  default     = false
}

variable "ingress_depends_on_id" {
  description = "Optional opaque dependency ID to force apply ordering before creating LogScale resources (used to wait for an external TLS secret/certificate to exist)."
  type        = string
  default     = ""
}

# Deprecated: retained for backward compatibility with cloud provider wrappers (AWS, Azure, OCI).
# These variables are no longer used by any module but are accepted to avoid breaking callers.
variable "k8s_cluster_name" {
  description = "Deprecated: no longer used. Retained for backward compatibility with cloud provider wrappers."
  type        = string
  default     = ""
}

variable "existing_logscale_namespace" {
  description = "Deprecated: no longer used. Namespace is now managed via kubernetes_namespace_v1 with existence check."
  type        = bool
  default     = false
}

