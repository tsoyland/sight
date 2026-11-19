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

variable "registry_namespace" {
  description = "Container Registry namespace. Names are global across Scaleway, so it must be unique."
  type        = string
  default     = "sight-tobba"
}

variable "image_tag" {
  description = "Tag of the sight image to run (the deploy workflow passes the git commit SHA)."
  type        = string
}

variable "min_scale" {
  description = "Minimum running instances. 0 = scale to zero when idle (cheap, cold starts); 1 = always warm (use during events)."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.min_scale)
    error_message = "min_scale must be 0 or 1 (max_scale is 1 until SignalR has a backplane)."
  }
}

variable "hostname" {
  description = "Public hostname for the app (CNAME at Domeneshop points to the container_hostname output)."
  type        = string
  default     = "sight.tobba.no"
}

variable "enable_custom_domain" {
  description = "Set to true after the CNAME exists at Domeneshop, so Scaleway can issue a TLS certificate."
  type        = bool
  default     = false
}

variable "db_max_cpu" {
  description = "Upper CPU limit for the Serverless SQL Database (it scales between 0 and this)."
  type        = number
  default     = 1
}
