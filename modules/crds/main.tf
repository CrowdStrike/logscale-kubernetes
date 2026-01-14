/**
 * ## Module: kubernetes/crds
 * This module installs custom resource definitions (crds) into the Kubernetes environment and is run in advance of any other
 * kubernetes module to ensure successful terraform planning.
 *
 */

#This bypasses the issue of some of the CRDs existing in advance by applying directly with kubectl
#instead of using terraform resources. It's better than having to manually delete existing resources or import
#them into terraform manually.

resource "null_resource" "install_cert_manager" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${var.cm_crds_url}"
  }
}

# For installing the strimzi crds. This needs to be done in advance to make terraform plans work when building strimzi later.
resource "null_resource" "install_strimzi_crds" {
  count = var.provision_kafka_servers ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/${var.strimzi_operator_version}/strimzi-crds-${var.strimzi_operator_version}.yaml"
  }
}

# Humio Operator CRDs
data "http" "humiocluster" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioclusters.yaml"
}

data "http" "humioexternalclusters" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
}

data "http" "humioingesttokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioingesttokens.yaml"
}

data "http" "humioparsers" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioparsers.yaml"
}

data "http" "humiorepositories" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiorepositories.yaml"
}

data "http" "humioviews" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviews.yaml"
}

data "http" "humioalerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioalerts.yaml"
}

data "http" "humioactions" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioactions.yaml"
}

data "http" "humioscheduledsearches" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioscheduledsearches.yaml"
}

data "http" "humiofilteralerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiofilteralerts.yaml"
}

data "http" "humioaggregatealerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioaggregatealerts.yaml"
}

data "http" "humiobootstraptokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiobootstraptokens.yaml"
}

data "http" "humiofeatureflags" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiofeatureflags.yaml"
}
data "http" "humiogroups" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiogroups.yaml"
}
data "http" "humioorganizationpermissionroles" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioorganizationpermissionroles.yaml"
}
data "http" "humiosystempermissionroles" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiosystempermissionroles.yaml"
}
data "http" "humiousers" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiousers.yaml"
}
data "http" "humioviewpermissionroles" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviewpermissionroles.yaml"
}
data "http" "humioipfilters" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioipfilters.yaml"
}
data "http" "humiomulticlustersearchviews" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiomulticlustersearchviews.yaml"
}
data "http" "humioorganizationtokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioorganizationtokens.yaml"
}
data "http" "humiopdfrenderservices" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiopdfrenderservices.yaml"
}
data "http" "humiosystemtokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiosystemtokens.yaml"
}
data "http" "humioviewtokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviewtokens.yaml"
}

# Install Humio CRDs using null_resource to avoid for_each issues
resource "null_resource" "install_humio_crds" {
  count = var.humio_operator_version != null ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioclusters.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioingesttokens.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioparsers.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiorepositories.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviews.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioalerts.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioactions.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioscheduledsearches.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiofilteralerts.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioaggregatealerts.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiobootstraptokens.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiofeatureflags.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiogroups.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioorganizationpermissionroles.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiosystempermissionroles.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiousers.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviewpermissionroles.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioipfilters.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiomulticlustersearchviews.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioorganizationtokens.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiopdfrenderservices.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiosystemtokens.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviewtokens.yaml"
  }
}

