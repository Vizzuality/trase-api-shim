# output "lb_ip" {
#   value = module.load_balancer.lb_ip
# }

# output "lb_domains" {
#   value = module.load_balancer.lb_domains
# }

# output "lb_path_rules" {
#   value = module.load_balancer.lb_path_rules
# }

output "contexts_cloud_function_url" {
  value = module.contexts_cloud_function.function_uri
}

output "columns_cloud_function_url" {
  value = module.columns_cloud_function.function_uri
}

output "nodes_cloud_function_url" {
  value = module.nodes_cloud_function.function_uri
}

output "top_nodes_cloud_function_url" {
  value = module.top_nodes_cloud_function.function_uri
}
