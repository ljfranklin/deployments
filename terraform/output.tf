output "gce_region" {
  value = "${var.gce_region}"
}

output "gce_zone" {
  value = "${var.gce_zone}"
}

output "network_name" {
  value = "${google_compute_network.bosh.name}"
}

output "subnetwork_name" {
  value = "${google_compute_subnetwork.bosh.name}"
}

output "deployments_bucket_name" {
  value = "${google_storage_bucket.deployment-bucket.name}"
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
