terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

# Configure providers - adjust for your cluster
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "gitlab" {
  source = "../.."

  domain = var.domain
  email  = var.email

  # Target amd64 architecture
  architecture = "amd64"

  # Optional: Namespace configuration
  namespace        = var.namespace
  create_namespace = var.create_namespace

  # Optional: Storage configuration
  storage_class = var.storage_class

  # Optional: Resource configuration
  resources = var.resources

  # Optional: Feature flags
  enable_certmanager = var.enable_certmanager
  enable_prometheus  = var.enable_prometheus
  enable_grafana     = var.enable_grafana

  # Optional: Additional node selector
  node_selector = var.node_selector

  # Optional: Tolerations
  tolerations = var.tolerations

  # Optional: Additional Helm values
  additional_values = var.additional_values

  # Optional: Passwords
  gitlab_root_password = var.gitlab_root_password
  postgresql_password  = var.postgresql_password
  redis_password       = var.redis_password
}

output "gitlab_url" {
  value = module.gitlab.gitlab_url
}

output "registry_url" {
  value = module.gitlab.registry_url
}

output "namespace" {
  value = module.gitlab.namespace
}

output "architecture" {
  value = module.gitlab.architecture
}
