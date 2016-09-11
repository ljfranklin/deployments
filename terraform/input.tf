variable "projectid" {
    type = "string"
}

variable "region" {
    type = "string"
    default = "us-central1"
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
