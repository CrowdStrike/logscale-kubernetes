
variable "logscale_cluster_type" {
  description = "Logscale cluster type"
  type        = string
}

variable "name_prefix" {
  type = string
  description = "Identifier attached to named resources to help them stand out."
}

variable "logscale_public_fqdn" {
  type = string
  description = "The FQDN tied to the public IP address for logscale ingress. This is the resource that will have a certificate provisioned from let's encrypt."
}

variable "kafka_broker_servers" {
  type = string
  description = "Kafka connection string used by logscale."
}

variable "humio_operator_version" {
  description = "The humio operator controls provisioning of logscale resources within kubernetes."
  type        = string
}
variable "humio_operator_chart_version" {
  description = "This is the version of the helm chart that installs the humio operator version chosen in variable humio_operator_version."
  type        = string
}

variable "humio_operator_repo" {
  description = "The humio operator repository."
  type        = string
  default     = "https://humio.github.io/humio-operator"
}

variable "logscale_image_version" {
  description = "The version of logscale to install."
  type        = string
  default     = ""
}

variable "logscale_image" {
  description       = "This can be used to specify a full image ref spec. The expectation is that the imagePullSecrets kubernetes secret will exist."
  type              = string
  default           = null
}

variable "image_pull_secret" {
  description       = "The kubernetes secret containing credentials to access the image repository. Required when setting logscale_image."
  type              = string
  default           = "regcred"
}

variable "humio_operator_extra_values" {
  description = "Resource Management for logscale pods"
  type        = map(string)
} 

variable "target_replication_factor" {
  description = "The default replication factor for logscale."
  type = number
  default = 2
}



# Resources for digest nodes
variable "logscale_digest_pod_count" {}
variable "logscale_digest_resources" {}
variable "logscale_digest_data_disk_size" {}
variable "kube_storage_class_for_logscale" {
    description = "Kubernetes storage class to use when provisioning persistent claims for digest nodes."
    #default = "acstor-ephemeraldisk-nvme"
    
    default = "topolvm-provisioner"
    type = string
}

# Resources for ui/query coordinator nodes
variable "logscale_ui_resources" {}
variable "logscale_ui_pod_count" {}
variable "logscale_ui_data_disk_size" {}
variable "kube_storage_class_for_logscale_ui" {
  description = "Storage class to be used for LogScale UI PVCs."
  default = "default"
  type = string
}

# Resources for ingest nodes
variable "logscale_ingest_pod_count" {}
variable "logscale_ingest_resources" {}
variable "logscale_ingest_data_disk_size" {}
variable "kube_storage_class_for_logscale_ingest" {
  description = "Storage class to be used for LogScale Ingest PVCs."
  default = "default"
  type = string
}

# Variables to allow for custom provided TLS certificate


variable "cert_issuer_name" {
  description = "Certificates issuer name for the Logscale Cluster"
  type        = string
}

variable "k8s_namespace_prefix" {
  description       = "Multiple namespaces will be created to contain resources using this prefix."
  type              = string
  default           = "log"
}

variable "provision_kafka_servers" {
  description = "Set this to true if we provisioned strimzi kafka servers during this process."
  type = bool
}

variable "use_custom_certificate" {
  default = false
  type = bool
  description = "Use a custom provided certificate on the frontend instead of Let's Encrypt?"
}

variable "k8s_secret_static_user_logins" {
  type = string
  description = "The k8s secret containing that static user logon list"
}

variable "k8s_secret_logscale_license" {
  type = string
  description = "The k8s secret containing the logscale license."
}

variable "k8s_secret_user_tls_cert" {
  type = string
  description = "The k8s secret containing the user provided TLS cert for logscale"
  default = null
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
}

variable "logscale_update_strategy" {
  description = "When describing a HumioCluster resource, you can provide a map value to describe how updates should be applied. Defaults to RollingUpdate, 50% maximum unavailable, zone awareness enabled."
  type = map
  default = {
      type                  = "RollingUpdate"
      enableZoneAwareness   = true
      minReadySeconds       = 120
      maxUnavailable        = "50%"
    }    
}

# Enable flags for different ingress types
variable "enable_nginx_ingress" {
  description = "Enable nginx ingress controller"
  type        = bool
  default     = true
}

variable "enable_pdf_render_service" {
  description = "Enable PDF render service"
  type        = bool
  default     = true
}

variable "pdf_render_service_image" {
  description = "Docker image of the PDF render service"
  type        = string
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
  default     = true
}