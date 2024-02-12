output "lb_ip" {
  value = module.load_balancer.lb_ip
}

output "lb_domains" {
  value = module.load_balancer.lb_domains
}

output "lb_path_rules" {
  value = module.load_balancer.lb_path_rules
}

# output "contexts_cloud_function_url" {
#   value = local.contexts_cf_lb_url
# }

# output "columns_cloud_function_url" {
#   value = local.columns_cf_lb_url
# }

# output "nodes_cloud_function_url" {
#   value = local.nodes_cf_lb_url
# }

# output "top_nodes_cloud_function_url" {
#   value = local.top_nodes_cf_lb_url
# }
