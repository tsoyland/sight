variable "region" {
  description = "Scaleway region for all resources."
  type        = string
  default     = "fr-par"
}

variable "app_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "sight"
}

variable "hostname" {
  description = "Public hostname for the app (CNAME at Domeneshop points here)."
  type        = string
  default     = "sight.tobba.no"
}

variable "enable_custom_domain" {
  description = "Set to true after the CNAME exists at Domeneshop, so Scaleway can issue a TLS certificate."
  type        = bool
  default     = false
}
