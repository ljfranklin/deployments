output "network_name" {
  value = "${google_compute_network.bosh.name}"
}

output "subnetwork_name" {
  value = "${google_compute_subnetwork.bosh.name}"
}

output "bosh_external_ip" {
  value = "${google_compute_address.director.address}"
}

output "concourse_external_ip" {
  value = "${google_compute_address.concourse.address}"
}

output "vault_external_ip" {
  value = "${google_compute_address.vault.address}"
}
