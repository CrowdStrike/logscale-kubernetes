variable "resource_name_prefix" {
  type              = string
  default           = "ls"
  description       = "Identifier attached to named resources to help them stand out. Must be 8 or fewer characters which can include lower case, numbers, and hyphens."

  validation {
    condition       = length(var.resource_name_prefix) <= 8 && can(regex("^[a-z0-9-]*$", var.resource_name_prefix))
    error_message   = "The resource_name_prefix is invalid."
  }
}

variable "k8s_cluster_context" {
  type              = string
  description       = "Name of the kubernetes cluster"
}

variable "logscale_public_fqdn" {
  type              = string
  description       = "The public FQDN of the LogScale cluster"
}

variable "nginx_ingress_sets" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}


variable "tags" {
  type              = map
  description       = "A map of tags to apply to all created resources." 
  default           = {}
}

variable "logscale_cluster_type" {
  description       = "Logscale cluster type"
  type              = string

  validation {
    condition       = contains(["basic", "ingress", "dedicated-ui", "advanced"], var.logscale_cluster_type)
    error_message   = "logscale_cluster_type must be one of: basic, ingress, or advanced"
  }
}

variable "logscale_cluster_size" {
  description       = "Size of the cluster to build. Reference cluster_size.tpl for definitions."
  type              = string
  default           = "xsmall"

  validation {
    condition       = contains(["xsmall", "small", "medium", "large", "xlarge"], var.logscale_cluster_size)
    error_message   = "logscale_cluster_size must be one of: xsmall, small, medium, large, xlarge"
  }
}

variable "node_group_definitions" {
  description       = "Node group sizing specification override"
  type              = any
  default           = {}
}

variable "humio_operator_version" {
  description       = "The humio operator controls provisioning of logscale resources within kubernetes."
  type              = string
  default           = "0.32.0"
}

variable "humio_operator_chart_version" {
  description       = "This is the version of the helm chart that installs the humio operator version chosen in variable humio_operator_version."
  type              = string
  default           = "0.32.0"
}

variable "cm_repo" {
  description       = "The cert-manager repository."
  type              = string
  default           = "https://charts.jetstack.io"
}

variable "cm_version" {
  description       = "The cert-manager helm chart version"
  type              = string
  default           = "v1.17.1"
}

variable "humio_operator_repo" {
  description       = "The humio operator repository."
  type              = string
  default           = "https://humio.github.io/humio-operator"
}


variable "logscale_image_version" {
  description       = "The version of logscale to install."
  type              = string
  default           = "1.211.0"
}

variable "logscale_image" {
  description       = "This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist."
  type              = string
  default           = null
}

variable "logscale_license" {
  description       = "Your logscale license data."
  type              = string
}

variable "humio_operator_extra_values" {
  description       = "Resource Management for logscale pods"
  type              = map(string)
  default = {
    "operator.resources.limits.cpu"      = "250m"
    "operator.resources.limits.memory"   = "750Mi"
    "operator.resources.requests.cpu"    = "250m"
    "operator.resources.requests.memory" = "750Mi"
  }
}

# TODO: Validate if byo kafka cluster is enabled.
variable "strimzi_operator_chart_version" {
  type            = string
  description     = "Helm chart version for installing strimzi."
  default         = "0.47.0"
}

# TODO: Validate if byo kafka cluster is enabled.
variable "strimzi_operator_version" {
  type            = string
  description     = "Strimzi operator version for resource definition installation."
  default         = "0.47.0" 
}

variable "strimzi_operator_repo" {
  type            = string
  description     = "Strimzi operator repo."
  default         = "https://strimzi.io/charts/"
}

variable "cert_issuer_kind" {
  description       = "Certificates issuer kind for the Logscale cluster."
  type              = string
  default           = "ClusterIssuer"
}

variable "cert_issuer_name" {
  description       = "Certificates issuer name for the Logscale Cluster"
  type              = string
  default           = "letsencrypt-cluster-issuer"
}

variable "cert_issuer_email" {
  description       = "Certificates issuer email address used with certificates provisioned in the cluster."
  type              = string
}

variable "cert_issuer_private_key" {
  description       = "This is the kubernetes secret where the private key for the certificate issuer will be stored."
  type              = string
  default           = "letsencrypt-cluster-issuer-key"
}

variable "cert_ca_server" {
  description       = "Certificate Authority Server."
  type              = string
  default           = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "password_rotation_arbitrary_value" {
  type            = string
  description     = "This will not influence the password generated for logscale but, when modified, will cause the password to be regenerated."
  default         = "defaultstring"
}

variable "provision_kafka_servers" {
  description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
  default = true
  type = bool
}

variable "byo_kafka_connection_string" {
  description = "Your own kafka environment connection string."
  default = ""
  type = string
}

variable "logscale_namespace" {
  description       = "The kubernetes namespace used by strimzi, logscale, and nginx-ingress."
  type              = string
  default           = "logging"
}

variable "cm_namespace" {
  description       = "Kubernetes namespace used by cert-manager."
  type              = string
  default           = "cert-manager"
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
  default           = "log"
}

variable "user_logscale_envvars" {
  type = list(object({
    name=string,
    value=optional(string)
    valueFrom=optional(object({
      secretKeyRef = object({
        name = string
        key = string
      })
    }))
  }))
  description = "These are environment variables passed into the HumioCluster resource spec definition that will be used for all created logscale instances. Supports string values and kubernetes secret refs. Will override any values defined by default in the configuration."
  default = []
}

variable "extra_humio_cluster_spec" {
  description = "Extra Humio cluster spec key-values"
  type        = any
  default     = {}
}

variable "extra_nginx_annotations" {
  description = "Extra annotations to add to the nginx ingress controller."
  type        = map
  default     = {}
}

variable "ingress_class_name" {
  description = "Class name of the nginx ingress controller."
  type        = string
  default     = "nginx"
}

variable "k8s_config_path" {
  description = "The path that will contain the kubernetes configuration file, typically at ~/.kube/config"
  default = "~/.kube/config"
}

variable "topo_lvm_chart_version" {
  description = "Version of topo lvm to install."
  type = string
  default = "15.6.0"
}

variable "use_topo_lvm" {
  default = true
  type = bool
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

variable "pvc_storage_class" {
  default = "topolvm-provisioner"
  type = string
  description = "Storage class to use for PVC"
}

variable "nginx_ingress_helm_chart_version" {
  description = "The version of nginx-ingress to install in the environment. Reference: github.com/kubernetes/ingress-nginx for helm chart version to nginx version mapping."
  type = string
  default = "4.12.1"
}

variable "use_own_certificate_for_ingress" {
  default = false
  type = bool
  description = "Set to true if you plan to bring your own certificate for logscale ingest/ui access."
}

variable "logscale_update_strategy" {
  description = "When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdate, 50% maximum unavailable, zone awareness enabled. Reference: https://github.com/humio/humio-operator/blob/master/docs/api.md#humioclusterspecupdatestrategy"
  type = map
  default = {
      type                  = "RollingUpdate"
      enableZoneAwareness   = true
      minReadySeconds       = 120
      maxUnavailable        = "50%"
    }    
}

variable "deploy_nginx_ingress" {
  description = "Deploy a nginx ingress controller"
  type        = bool
  default     = true
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

variable "pdf_render_service_port" {
  description = "Port of the PDF render service"
  type        = string
  default     = "5123"
}

variable "enable_scheduled_report" {
  description = "Enable scheduled report functionality"
  type        = bool
  default     = false
}