output "lb_ip" {
  description = "The public IP address of the load balancer"
  value       = google_compute_global_address.ip_address.address
}

output "lb_domains" {
  value = google_compute_managed_ssl_certificate.load-balancer-certificate.managed.*.domains
}

output "lb_path_rules" {
  value = google_compute_url_map.load-balancer-url-map.path_matcher.*.path_rule
}