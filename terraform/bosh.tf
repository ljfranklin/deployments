provider "google" {
    project = "${var.projectid}"
    region = "${var.gce_region}"
    credentials = "${var.gce_credentials_json}"
}

provider "cloudflare" {
    email = "${var.cloudflare_email}"
    api_token = "${var.cloudflare_token}"
}

resource "google_compute_network" "bosh" {
  name = "bosh"
  auto_create_subnetworks = false
}

// Subnet for the BOSH director
resource "google_compute_subnetwork" "bosh" {
  name          = "bosh"
  ip_cidr_range = "10.0.0.0/24"
  network       = "${google_compute_network.bosh.self_link}"
}

// Allow SSH to Director
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh-bosh"
  network = "${google_compute_network.bosh.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-external", "concourse-external", "vault-external"]
}

// Allow CLI access to Director
resource "google_compute_firewall" "allow-bosh-director" {
  name    = "allow-bosh-director"
  network = "${google_compute_network.bosh.name}"

  allow {
    protocol = "tcp"
    ports    = ["25555", "6868"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-external"]
}

// Allow Concourse access
resource "google_compute_firewall" "allow-concourse" {
  name    = "allow-concourse"
  network = "${google_compute_network.bosh.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2222"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["concourse-external"]
}

// Allow open access between internal VMs
resource "google_compute_firewall" "bosh-internal" {
  name    = "bosh-internal"
  network = "${google_compute_network.bosh.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
  target_tags = ["bosh-internal"]
  source_tags = ["bosh-internal"]
}

resource "google_storage_bucket" "deployment-bucket" {
  name = "${var.deployments_bucket_name}"
}

resource "google_compute_address" "director" {
  name = "bosh-director-ip"
}

resource "google_compute_address" "concourse" {
  name = "concourse-ip"
}

resource "cloudflare_record" "bosh-dns" {
    zone_id = "${var.cloudflare_domain}"
    name = "bosh"
    value = "${google_compute_address.director.address}"
    type = "A"
    proxied = false
}

resource "cloudflare_record" "concourse-dns" {
    zone_id = "${var.cloudflare_domain}"
    name = "concourse"
    value = "${google_compute_address.concourse.address}"
    type = "A"
    proxied = false
}
