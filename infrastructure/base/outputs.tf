# output "staging_contexts_cloud_function_url" {
#   value = module.staging.contexts_cloud_function_url
# }

output "dns_name_servers" {
  value = module.dns.dns_name_servers
}

output "lb_ip" {
  value = module.production.lb_ip
}

output "lb_domains" {
  value = module.production.lb_domains
}

output "lb_path_rules" {
  value = module.production.lb_path_rules
}