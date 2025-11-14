/*
 * ## Module: kubernetes/logscale
 * This module provisions the Humio Operator in the target kubernetes environment and installs manifests that instruct the Humio Operator
 * on the Logscale cluster to build. This also controls creation of ingress points for the nginx-ingress controllers to route traffic
 * to Logscale systems.
 * 
 */

# Check for humio-cluster CRD
data "kubernetes_resources" "check_humio_cluster_crd" {
  api_version    = "apiextensions.k8s.io/v1"
  kind           = "CustomResourceDefinition"
  field_selector = "metadata.name=humioclusters.core.humio.com"
}
