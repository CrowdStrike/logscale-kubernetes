

variable "cm_crds_url" {
  description = "Cert Manager CRDs URL"
  type        = string
  default     = "https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml"
}

variable "humio_operator_version" {
  description = "Humio Operator version"
  type        = string
}

variable "strimzi_operator_version" {
  description = "Used to get CRDs for strimzi and install them."
  type = string
}

variable "provision_kafka_servers" {
  description = "Set this to true to provision strimzi kafka within this kubernetes cluster. It should be false if you are bringing your own kafka implementation."
  default = true
  type = bool
}