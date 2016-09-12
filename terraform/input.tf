variable "projectid" {
    type = "string"
}

variable "gce_credentials_json" {
    type = "string"
}

variable "region" {
    type = "string"
    default = "us-central1"
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
