output "master_ipv4" {
  value = "${hcloud_server.server.ipv4_address}"
}
