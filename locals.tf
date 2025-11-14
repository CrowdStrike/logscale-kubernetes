# This random string is used as part of resource naming. It can be changed or ignored as necessary.
resource "random_string" "name-modifier" {
    length = 5
    special = false
    upper = false
}

locals {  
  # Render a template of available cluster sizes
  cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))

  cluster_size_rendered = {
    for key in keys(local.cluster_size_template) :
    key => local.cluster_size_template[key]
  }

  node_group_definitions = merge(local.cluster_size_rendered[var.logscale_cluster_size], var.node_group_definitions)

  resource_name_prefix = "z${random_string.name-modifier.result}-${var.resource_name_prefix}"
}
