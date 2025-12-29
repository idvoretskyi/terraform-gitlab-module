output "namespace" {
  description = "Namespace where GitLab is deployed"
  value       = var.create_namespace ? kubernetes_namespace.gitlab[0].metadata[0].name : var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.gitlab.name
}

output "release_version" {
  description = "Deployed GitLab chart version"
  value       = helm_release.gitlab.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.gitlab.status
}

output "gitlab_url" {
  description = "GitLab URL"
  value       = "https://gitlab.${var.domain}"
}

output "registry_url" {
  description = "GitLab Container Registry URL"
  value       = "https://registry.${var.domain}"
}

output "minio_url" {
  description = "MinIO URL"
  value       = "https://minio.${var.domain}"
}

output "architecture" {
  description = "Target architecture for the deployment"
  value       = var.architecture
}

output "node_selector" {
  description = "Node selector applied to GitLab pods"
  value       = local.base_node_selector
}

output "helm_values" {
  description = "Final Helm values used for deployment (sensitive)"
  value       = local.helm_values
  sensitive   = true
}
