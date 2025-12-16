/**
 * ## main.tf
 * This is the core wrapper around all modules provided in this terraform and serves as an example of
 * how to run this terraform to deploy LogScale within your Kubernetes environment.
 *
 */

# Install custom resource definitions in the kubernetes cluster.
# Requires kubectl to be appropriately configured on your endpoint
module "crds" {
  source                                        = "./modules/crds"
  humio_operator_version                        = var.humio_operator_version
  strimzi_operator_version                      = var.strimzi_operator_version
  provision_kafka_servers                       = var.provision_kafka_servers

  providers = {
    kubernetes = kubernetes
  }
}

# Install kubernetes app: Strimzi
module "kafka" {
  source                                        = "./modules/strimzi"
  count                                         = var.provision_kafka_servers == true ? 1 : 0

  k8s_namespace_prefix                          = var.k8s_namespace_prefix
  
  strimzi_operator_chart_version                = var.strimzi_operator_chart_version
  strimzi_operator_repo                         = var.strimzi_operator_repo

  kube_storage_class_for_kafka                  = lookup(local.node_group_definitions, "kafka_broker_data_storage_class", var.pvc_storage_class)
  kafka_broker_pod_replica_count                = local.node_group_definitions["kafka_broker_pod_replica_count"]
  kafka_broker_resources                        = local.node_group_definitions["kafka_broker_resources"]
  kafka_broker_data_disk_size                   = local.node_group_definitions["kafka_broker_data_disk_size"]
  num_kafka_volumes                             = local.node_group_definitions["kafka_broker_disk_count"]
 
  name_prefix                                   = var.resource_name_prefix
        
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

/*
Install additional prerequisites: 
  * topolvm
  * cert-manager
  * nginx-ingress

And adds associated configurations. It's separated from the logscale module to make it easier to destroy/rebuild logscale by itself without
touching these resources that need changing less frequently.
*/
module "logscale-prereqs" {
  source                                        = "./modules/logscale-prereqs"
  # Configuration for cert-manager
  cm_repo                                       = var.cm_repo
  cm_version                                    = var.cm_version

  # Used for nginx-ingress
  k8s_namespace_prefix                          = var.k8s_namespace_prefix
  nginx_ingress_sets                            = var.nginx_ingress_sets
  logscale_cluster_type                         = var.logscale_cluster_type
  logscale_ingress_pod_count                    = local.node_group_definitions["logscale_ingress_desired_node_count"]
  logscale_ingress_min_pod_count                = local.node_group_definitions["logscale_ingress_min_node_count"]
  logscale_ingress_max_pod_count                = local.node_group_definitions["logscale_ingress_max_node_count"]
  logscale_ingress_resources                    = var.logscale_cluster_type == "basic" ? local.node_group_definitions["logscale_basic_ingress_resources"] : local.node_group_definitions["logscale_ingress_resources"]
  logscale_ingress_data_disk_size               = local.node_group_definitions["logscale_ingress_data_disk_size"]

  logscale_public_fqdn                          = var.logscale_public_fqdn

  topo_lvm_chart_version                        = var.topo_lvm_chart_version
  topo_lvm_controller_replicas                  = var.topo_lvm_controller_replicas
  topo_lvm_disk_pattern                         = var.topo_lvm_disk_pattern
  use_topo_lvm                                  = var.use_topo_lvm

  # Storage class configuration for conditional topo-lvm deployment
  kafka_broker_data_storage_class               = lookup(local.node_group_definitions, "kafka_broker_data_storage_class", var.pvc_storage_class)
  logscale_ui_data_storage_class                = lookup(local.node_group_definitions, "logscale_ui_data_disk_type", var.pvc_storage_class)
  logscale_ingest_data_storage_class            = lookup(local.node_group_definitions, "logscale_ingest_data_disk_type", var.pvc_storage_class)
  
  nginx_ingress_helm_chart_version              = var.nginx_ingress_helm_chart_version
  deploy_nginx_ingress                          = var.deploy_nginx_ingress
  
  # Used for let's encrypt certificate issuer
  cert_issuer_kind                              = var.cert_issuer_kind
  cert_issuer_email                             = var.cert_issuer_email
  cert_ca_server                                = var.cert_ca_server
  cert_issuer_private_key                       = var.cert_issuer_private_key
  cert_issuer_name                              = var.cert_issuer_name

  # Used everywhere for naming of resources
  name_prefix                                   = var.resource_name_prefix

  # Configure the kubernetes provider    
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  # Security
  use_custom_certificate                        = var.use_own_certificate_for_ingress
 
  logscale_license                              = var.logscale_license
  password_rotation_arbitrary_value             = var.password_rotation_arbitrary_value

  depends_on = [
    module.crds
  ]
}

# Install the Humio Operator and logscale cluster definitions.
module "logscale" {
  source                                        = "./modules/logscale"

  k8s_namespace_prefix                          = var.k8s_namespace_prefix

  logscale_cluster_type                         = var.logscale_cluster_type

  logscale_image_version                        = var.logscale_image_version
  logscale_image                                = var.logscale_image
  humio_operator_extra_values                   = var.humio_operator_extra_values
  humio_operator_repo                           = var.humio_operator_repo
  humio_operator_chart_version                  = var.humio_operator_chart_version
  humio_operator_version                        = var.humio_operator_version

  cert_issuer_name                              = var.cert_issuer_name

  user_logscale_envvars                         = var.user_logscale_envvars
  extra_humio_cluster_spec                      = var.extra_humio_cluster_spec
  extra_nginx_annotations                       = var.extra_nginx_annotations
  ingress_class_name                            = var.ingress_class_name

  # Enable flags for different ingress types
  enable_nginx_ingress                          = var.deploy_nginx_ingress

  # Cloud-agnostic configuration
  name_prefix                                   = var.resource_name_prefix
  
  target_replication_factor                     = local.node_group_definitions["logscale_target_replication_factor"]

  logscale_digest_pod_count                     = local.node_group_definitions["logscale_digest_pod_count"]
  logscale_digest_resources                     = local.node_group_definitions["logscale_digest_resources"]
  logscale_digest_data_disk_size                = local.node_group_definitions["logscale_digest_data_disk_size"]
  kube_storage_class_for_logscale               = lookup(local.node_group_definitions, "logscale_digest_data_disk_type", var.pvc_storage_class)
  
  logscale_ui_resources                         = local.node_group_definitions["logscale_ui_resources"]
  logscale_ui_pod_count                         = local.node_group_definitions["logscale_ui_pod_count"]
  logscale_ui_data_disk_size                    = local.node_group_definitions["logscale_ui_data_disk_size"]
  kube_storage_class_for_logscale_ui            = lookup(local.node_group_definitions, "logscale_ui_data_disk_type", var.pvc_storage_class)

  logscale_ingest_pod_count                     = local.node_group_definitions["logscale_ingest_pod_count"]
  logscale_ingest_resources                     = local.node_group_definitions["logscale_ingest_resources"]
  logscale_ingest_data_disk_size                = local.node_group_definitions["logscale_ingest_data_disk_size"]
  kube_storage_class_for_logscale_ingest        = lookup(local.node_group_definitions, "logscale_ingest_data_disk_type", var.pvc_storage_class)

  # Kafka - BYOK / Strimzi
  provision_kafka_servers                       = var.provision_kafka_servers
  kafka_broker_servers                          = var.provision_kafka_servers ? module.kafka[0].kafka-connection-string : var.byo_kafka_connection_string

  logscale_public_fqdn                          = var.logscale_public_fqdn

  use_custom_certificate                        = var.use_own_certificate_for_ingress

  enable_pdf_render_service                     = var.enable_pdf_render_service
  pdf_render_service_image                      = var.pdf_render_service_image
  pdf_render_service_node_count                 = var.pdf_render_service_node_count

  # In the pre-req module, we store kuberentes secrets used to configure
  # logscale which are referenced here.
  k8s_secret_static_user_logins                 = module.logscale-prereqs.k8s_secret_static_user_logins
  k8s_secret_logscale_license                   = module.logscale-prereqs.k8s_secret_logscale_license

  logscale_update_strategy                      = var.logscale_update_strategy

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [
    module.logscale-prereqs
  ]
}
