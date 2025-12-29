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

variable "release_name" {
  description = "Helm release name for GitLab"
  type        = string
  default     = "gitlab"
}

variable "chart_version" {
  description = "GitLab Helm chart version"
  type        = string
  default     = "9.7.0"
}

variable "chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://charts.gitlab.io/"
}

variable "domain" {
  description = "Base domain for GitLab (e.g., gitlab.example.com)"
  type        = string
}

variable "email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
}

variable "architecture" {
  description = "Target architecture for GitLab deployment (amd64 or arm64)"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Architecture must be either 'amd64' or 'arm64'."
  }
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

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
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

variable "node_selector" {
  description = "Node selector for pod assignment (useful for architecture-specific scheduling)"
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

variable "ingress_class" {
  description = "Ingress class to use (e.g., nginx, traefik)"
  type        = string
  default     = "nginx"
}

variable "additional_values" {
  description = "Additional Helm values to merge with the defaults (as YAML string)"
  type        = string
  default     = ""
}

variable "timeout" {
  description = "Timeout for Helm operations (in seconds)"
  type        = number
  default     = 900
}

variable "atomic" {
  description = "If set, installation process purges chart on fail"
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait for all resources to be ready before marking release as successful"
  type        = bool
  default     = true
}
