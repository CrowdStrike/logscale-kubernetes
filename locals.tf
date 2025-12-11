locals {  
  # Render a template of available cluster sizes
  cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))

  cluster_size_rendered = {
    for key in keys(local.cluster_size_template) :
    key => local.cluster_size_template[key]
  }

  node_group_definitions = merge(local.cluster_size_rendered[var.logscale_cluster_size], var.node_group_definitions)
}
