variable "domain" {
  description = "Base domain for GitLab (e.g., gitlab.example.com)"
  type        = string
}

variable "email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where GitLab will be deployed"
  type        = string
  default     = "gitlab"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
}

variable "resources" {
  description = "Resource requests and limits for GitLab components"
  type = object({
    webservice = optional(object({
      requests = optional(object({
        cpu    = optional(string, "200m")
        memory = optional(string, "1.5Gi")
      }))
      limits = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "2Gi")
      }))
    }))
    sidekiq = optional(object({
      requests = optional(object({
        cpu    = optional(string, "200m")
        memory = optional(string, "1Gi")
      }))
      limits = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "2Gi")
      }))
    }))
  })
  default = {}
}

variable "enable_certmanager" {
  description = "Enable cert-manager for TLS certificate management"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus for monitoring"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana for visualization"
  type        = bool
  default     = true
}

variable "node_selector" {
  description = "Additional node selector for pod assignment (beyond architecture)"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod scheduling"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "additional_values" {
  description = "Additional Helm values to merge with the defaults (as YAML string)"
  type        = string
  default     = ""
}

variable "gitlab_root_password" {
  description = "Root password for GitLab (if not set, one will be auto-generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgresql_password" {
  description = "Password for PostgreSQL database"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_password" {
  description = "Password for Redis"
  type        = string
  default     = ""
  sensitive   = true
}
