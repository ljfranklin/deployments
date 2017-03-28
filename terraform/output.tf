output "gce_region" {
  value = "${var.gce_region}"
}

output "zone" {
  value = "${var.gce_zone}"
}

output "project_id" {
  value = "${var.projectid}"
}

output "network" {
  value = "${google_compute_network.bosh.name}"
}

output "subnetwork" {
  value = "${google_compute_subnetwork.bosh.name}"
}

output "internal_ip" {
  value = "${google_compute_address.director.address}"
}

output "internal_cidr" {
  value = "${google_compute_subnetwork.bosh.ip_cidr_range}"
}

output "internal_gw" {
  value = "${cidrhost(google_compute_subnetwork.bosh.ip_cidr_range, 1)}"
}

output "external_ip" {
  value = "${google_compute_address.director.address}"
}

output "tags" {
  value = ["bosh-internal", "bosh-external"]
}

output "concourse_external_ip" {
  value = "${google_compute_address.concourse.address}"
}

output "bosh_hostname" {
  value = "${cloudflare_record.bosh-dns.hostname}"
}

output "concourse_hostname" {
  value = "${cloudflare_record.concourse-dns.hostname}"
}

output "deployments_bucket_name" {
  value = "${google_storage_bucket.deployment-bucket.name}"
}
