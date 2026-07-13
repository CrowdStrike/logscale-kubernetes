# LogScale Kubernetes Terraform Modules 

This repository provides Terraform modules for deploying CrowdStrike LogScale on Kubernetes clusters across multiple cloud providers (AWS, Azure, and GCP) or on a bare-metal Kubernetes cluster.

## Overview

These modules handle the complete deployment of LogScale including:

- Custom Resource Definitions for the Humio Operator
- Prerequisite components (cert-manager, Gateway API, TopoLVM)
- Kafka infrastructure via Strimzi (optional)
- LogScale cluster deployment with configurable sizing


## Prerequisites

Before starting the deployment, ensure you have the following tools and access:

- **Terraform 1.5.7+**: Terraform is the infrastructure as code tool used to manage the deployment. Ensure you have version 1.1.0 or higher installed.
- **kubectl 1.27+**: kubectl is the command-line tool for interacting with the Kubernetes cluster. Make sure you have version 1.22 or above.
- **Helm v3**: Helm is the package manager for Kubernetes, used to manage Kubernetes applications. Ensure you have version 3 or higher installed.

## Modules

This repository contains several Terraform modules that work together to deploy LogScale components on Kubernetes clusters across different cloud providers (GCP, Azure, and AWS). Below is a description of each module and its role in the deployment process.

### Core Modules

#### `crds` Module

The Custom Resource Definitions (CRDs) module installs necessary Kubernetes CRDs before any other module runs.

**Purpose:**
- Installs CRDs for Humio Operator, Strimzi Kafka Operator, and Cert Manager
- Runs before other modules to ensure successful Terraform planning
- Uses `kubectl apply` for some resources to avoid conflicts with existing CRDs

**Key Components:**
- Humio/LogScale CRDs (HumioCluster, HumioExternalCluster, HumioIngestToken, etc.)
- Strimzi Kafka CRDs (when Kafka provisioning is enabled)
- Cert Manager CRDs

#### `logscale-prereqs` Module

This module installs prerequisites for running LogScale in Kubernetes.

**Purpose:**
- Sets up the foundation for LogScale deployment
- Creates resources that change less frequently than the LogScale deployment itself
- Allows rebuilding LogScale without affecting these underlying components

**Key Components:**
- Kubernetes Namespaces creation
- Cert Manager installation
- Let's Encrypt certificate issuer configuration
- Gateway API for managing connections to LogScale
- TopoLVM for managing storage on NVME-enabled nodes
- Kubernetes secrets used by LogScale (license, user logins, etc.)

#### `strimzi` Module

This module installs and configures Strimzi Kafka when the `provision_kafka_servers` variable is set to `true`.

**Purpose:**
- Provides Kafka infrastructure for LogScale's ingestion pipeline
- Configures Kafka in Kraft mode with appropriate replication and security settings

**Key Components:**
- Strimzi Kafka Operator installation via Helm
- Kafka cluster configuration with TLS security
- Node pool definitions for Kafka brokers and controllers
- Storage configuration for Kafka using persistent volumes
- Rack awareness for zone distribution

#### `logscale` Module

This module installs the Humio Operator and LogScale cluster definitions.

**Purpose:**
- Deploys the core LogScale components
- Configures the LogScale cluster based on the selected cluster type and size

**Key Components:**
- Humio Operator installation
- LogScale cluster definition based on cluster type (basic, ingress, dedicated-ui, advanced)
- Ingress configuration for UI and API access
- Integration with Kafka (either provisioned by Strimzi or bring-your-own)
- Resource allocation based on cluster size

### Module Relationships

The modules are designed to be used in a specific order:

1. **crds**: First, all required Custom Resource Definitions are installed
2. **logscale-prereqs**: Next, prerequisites like namespaces, cert-manager, and storage are configured
3. **strimzi** (conditional): If `provision_kafka_servers = true`, Kafka infrastructure is deployed
4. **logscale**: Finally, the LogScale cluster itself is deployed

This modular approach allows for:
- Separation of concerns between different components
- Ability to update or replace individual components without affecting others
- Flexibility to use different configurations for different environments
- Support for multiple cloud providers through consistent abstractions

### Cloud-Specific Considerations

While the modules are designed to be cloud-agnostic, certain configurations may be optimized for specific cloud providers:

- **AWS**: When deploying on AWS, you can integrate with services like EKS, MSK for Kafka, and use ALB for ingress
- **Azure**: On Azure, the modules can leverage AKS and Azure-specific storage classes
- **GCP**: For Google Cloud, the modules can work with GKE and GCP-specific resources


## Terraform Variables in `terraform.tfvars`

This section describes the variables that can be configured in your `terraform.tfvars` file to customize the LogScale Kubernetes deployment.

### General Configuration

| Variable Name          | Description                                      | Type   | Default | Example                        |
|------------------------|--------------------------------------------------|--------|---------|--------------------------------|
| `resource_name_prefix` | Prefix attached to named resources.              | string | `"log"` | `"log"`                        |
| `tags`                 | A map of tags to apply to all created resources. | map    | `{}`    | `{ resourceOwner = "myteam" }` |

### Kubernetes Configuration

| Variable Name           | Description                                                   | Type   | Default           | Example             |
|-------------------------|---------------------------------------------------------------|--------|-------------------|---------------------|
| `k8s_cluster_context`   | Name of the kubernetes cluster context.                       | string | -                 | `"colima"`          |
| `kubeconfig_path`       | Absolute path to a cluster-specific kubeconfig file.          | string | `""`              | `"/path/to/kubeconfig-aks-mycluster.yaml"` |
| `k8s_namespace_prefix`  | Prefix applied to all created namespaces.                     | string | `"log"`           | `"logscale"`        |
| `logscale_namespace`    | The kubernetes namespace used logscale.                       | string | `"logging"`       | -                   |
| `cm_namespace`          | Kubernetes namespace used by cert-manager.                    | string | `"cert-manager"`  | -                   |


### LogScale Configuration

| Variable Name               | Description                                                                         | Type         | Default          | Example                                                        |
|-----------------------------|-------------------------------------------------------------------------------------|--------------|------------------|----------------------------------------------------------------|
| `logscale_public_fqdn`      | The public FQDN of the LogScale cluster.                                            | string       | -                | `"logscale.mydomain.com"`                                      |
| `logscale_cluster_type`     | LogScale cluster type. Must be one of: basic, ingress, dedicated-ui, or advanced.   | string       | -                | `"basic"`                                                      |
| `logscale_cluster_size`     | Size of the cluster to build. Must be one of: xsmall, small, medium, large, xlarge. | string       | `"xsmall"`       | `"xsmall"`                                                     |
| `logscale_license`          | Your LogScale license data.                                                         | string       | -                | `"eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiJ9..."`                    |
| `logscale_image_version`    | The version of LogScale to install.                                                 | string       | `""`             | `"1.194.0"`                                                    |
| `logscale_image`            | This can be used to specify a full image ref spec.                                  | string       | `null`           | -                                                              |
| `node_group_definitions`    | Node group sizing specification override.                                           | any          | `{}`             | -                                                              |
| `user_logscale_envvars`     | Environment variables passed into the HumioCluster resource spec definition.        | list(object) | `[]`             | `[ { "name" = "LOCAL_STORAGE_MIN_AGE_DAYS", "value" = "7" } ]` |
| `logscale_update_strategy`  | Describes how updates should be applied.                                            | map          | See variables.tf | See local-input.tfvars                                         |
| `extra_humio_cluster_spec`  | Extra Humio cluster spec key-values.                                                | map          | `{}`             | See commented example in local-input.tfvars                    |



### Certificate Management

| Variable Name                                       | Description                                                                                    | Type   | Default                                            | Example              |
|-----------------------------------------------------|------------------------------------------------------------------------------------------------|--------|----------------------------------------------------|----------------------|
| `cert_issuer_email`                                 | Certificates issuer email address used with certificates provisioned in the cluster.           | string | -                                                  | `"user@example.com"` |
| `cert_issuer_kind`                                  | Certificates issuer kind for the LogScale cluster.                                             | string | `"ClusterIssuer"`                                  | -                    |
| `cert_issuer_name`                                  | Certificates issuer name for the LogScale Cluster.                                             | string | `"letsencrypt-cluster-issuer"`                     | -                    |
| `cert_issuer_private_key`                           | This is the kubernetes secret where the private key for the certificate issuer will be stored. | string | `"letsencrypt-cluster-issuer-key"`                 | -                    |
| `cert_ca_server`                                    | Certificate Authority Server.                                                                  | string | `"https://acme-v02.api.letsencrypt.org/directory"` | -                    |
| `use_own_certificate_for_ingress`                   | Set to true if you plan to bring your own certificate for LogScale ingest/ui access.           | bool   | `false`                                            | `false`              |

### Kafka Configuration

| Variable Name                   | Description                                                                | Type   | Default                        | Example    |
|---------------------------------|----------------------------------------------------------------------------|--------|--------------------------------|------------|
| `provision_kafka_servers`       | Set to true to provision strimzi kafka within this kubernetes cluster.     | bool   | `true`                         | `true`     |
| `byo_kafka_connection_string`   | Your own kafka environment connection string.                              | string | `""`                           | -          |
| `strimzi_operator_chart_version`| Helm chart version for installing strimzi.                                 | string | `""`                           | `"0.45.0"` |
| `strimzi_operator_version`      | Strimzi operator version for resource definition installation.             | string | `""`                           | `"0.45.0"` |
| `strimzi_operator_repo`         | Strimzi operator repo.                                                     | string | `"https://strimzi.io/charts/"` | -          |

### Operator and Chart Versions

| Variable Name                 | Description                                                                       | Type        | Default                                    | Example                                     |
|-------------------------------|-----------------------------------------------------------------------------------|-------------|--------------------------------------------|---------------------------------------------|
| `humio_operator_version`      | The humio operator controls provisioning of logscale resources within kubernetes. | string      | -                                          | `"0.30.0"`                                  |
| `humio_operator_chart_version`| This is the version of the helm chart that installs the humio operator.           | string      | -                                          | `"0.30.0"`                                  |
| `humio_operator_repo`         | The humio operator repository.                                                    | string      | `"https://humio.github.io/humio-operator"` | -                                           |
| `humio_operator_extra_values` | Resource Management for logscale pods.                                            | map(string) | See variables.tf                           | See commented example in local-input.tfvars |
| `cm_repo`                     | The cert-manager repository.                                                      | string      | `"https://charts.jetstack.io"`             |                                             |
| `cm_version`                  | The cert-manager helm chart version.                                              | string      | -                                          | `"v1.17.1"`                                 |
| `topo_lvm_chart_version`      | Version of topo lvm to install.                                                   | string      | -                                          | `"15.5.2"`                                  |
| `topo_lvm_controller_replicas`| Number of replicas for the topo_lvm controller.                                   | number      | `2`                                        | `1`                                         |


### Ingress Configuration

| Variable Name                     | Description                                                 | Type         | Default  | Example                                     |
|-----------------------------------|-------------------------------------------------------------|--------------|----------|---------------------------------------------|
| `deploy_gateway_api`              | Deploy Gateway API and associated HTTPRoutes.               | bool         | `true`   | `false`                                     |
| `extra_gateway_annotations`       | Extra annotations to add to the Gateway API.                | map          | `{}`     | See commented example in local-input.tfvars |

### Password Management

| Variable Name                       | Description                                               | Type   | Default           | Example |
|-------------------------------------|-----------------------------------------------------------|--------|-------------------|---------|
| `password_rotation_arbitrary_value` | When modified, will cause the password to be regenerated. | string | `"defaultstring"` | -       |

## References
- [Cert Manager Documentation](https://cert-manager.io/docs/)
- [Humio Operator](https://github.com/humio/humio-operator)
