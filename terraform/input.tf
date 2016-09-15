variable "projectid" {
    type = "string"
}

variable "gce_credentials_json" {
    type = "string"
}

variable "gce_region" {
    type = "string"
    default = "us-central1"
}

variable "gce_zone" {
    type = "string"
    default = "us-central1-f"
}

variable "deployments_bucket_name" {
    type = "string"
}

variable "cloudflare_email" {
  type = "string"
}

variable "cloudflare_token" {
  type = "string"
}

variable "cloudflare_domain" {
  type = "string"
}
