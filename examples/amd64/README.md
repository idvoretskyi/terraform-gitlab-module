# GitLab AMD64 Deployment Example

This example deploys GitLab on amd64 (x86_64) architecture nodes. The configuration is generic and can be customized for different use cases (development, staging, production) and cloud providers.

## Prerequisites

- Kubernetes cluster with amd64 nodes
- kubectl configured to access the cluster
- Helm 3.x installed
- Ingress controller deployed (nginx, traefik, etc.)
- DNS configured to point your domain to the ingress

## Supported Platforms

- **AWS EKS**: t3/t2/m5/c5 instance families
- **Google Cloud GKE**: n2/n1/e2 machine families
- **Azure AKS**: Standard/DSv3/Dv3 VM series
- **Local Kubernetes**: k3d, kind, minikube (amd64)
- **Self-managed**: Any Kubernetes cluster with amd64 nodes

## Quick Start

1. **Copy and customize configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Deploy:**
   ```bash
   terraform plan
   terraform apply
   ```

4. **Get credentials:**
   ```bash
   kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
     -o jsonpath='{.data.password}' | base64 -d
   ```

5. **Access GitLab:**
   - URL: https://gitlab.example.com (your configured domain)
   - Username: `root`
   - Password: from step 4

## Configuration Examples

### Minimal (Development/Testing)

```hcl
domain = "gitlab.example.com"
email  = "admin@example.com"

resources = {
  webservice = {
    requests = { cpu = "100m", memory = "512Mi" }
    limits   = { cpu = "500m", memory = "1Gi" }
  }
  sidekiq = {
    requests = { cpu = "100m", memory = "512Mi" }
    limits   = { cpu = "500m", memory = "1Gi" }
  }
}

enable_prometheus = false
enable_grafana    = false
```

**Requirements:** 2 CPU cores, 4GB RAM

### Standard (Small Production)

```hcl
domain = "gitlab.example.com"
email  = "admin@example.com"

storage_class = "gp3"  # AWS example

resources = {
  webservice = {
    requests = { cpu = "500m", memory = "2Gi" }
    limits   = { cpu = "2", memory = "4Gi" }
  }
  sidekiq = {
    requests = { cpu = "500m", memory = "1.5Gi" }
    limits   = { cpu = "2", memory = "3Gi" }
  }
}

enable_certmanager = true
enable_prometheus  = true
enable_grafana     = true
```

**Requirements:** 8 CPU cores, 16GB RAM

### Enterprise (Large Production)

```hcl
domain = "gitlab.example.com"
email  = "admin@example.com"

namespace     = "gitlab-production"
storage_class = "pd-ssd"  # GCP example

resources = {
  webservice = {
    requests = { cpu = "2", memory = "4Gi" }
    limits   = { cpu = "4", memory = "8Gi" }
  }
  sidekiq = {
    requests = { cpu = "2", memory = "3Gi" }
    limits   = { cpu = "4", memory = "6Gi" }
  }
}

additional_values = <<-EOT
  global:
    backup:
      enabled: true
      schedule: "0 2 * * *"
    gitaly:
      enabled: true
EOT
```

**Requirements:** 16+ CPU cores, 32GB+ RAM

## Cloud Provider Specific Settings

### AWS EKS

```hcl
storage_class = "gp3"

node_selector = {
  "node.kubernetes.io/instance-type" = "t3.xlarge"
}
```

### Google Cloud GKE

```hcl
storage_class = "pd-balanced"

node_selector = {
  "cloud.google.com/machine-family" = "n2"
}
```

### Azure AKS

```hcl
storage_class = "managed-premium"

node_selector = {
  "kubernetes.azure.com/agentpool" = "gitlab"
}
```

## Post-Deployment

### Access Services

```bash
# GitLab UI
echo "https://gitlab.${DOMAIN}"

# Container Registry
echo "https://registry.${DOMAIN}"

# Grafana (if enabled)
kubectl port-forward -n gitlab svc/gitlab-grafana 3000:80
```

### Configure CI/CD

The deployment includes GitLab Runner. Register additional runners:

```bash
# Get runner registration token
kubectl get secret gitlab-gitlab-runner-secret -n gitlab \
  -o jsonpath='{.data.runner-registration-token}' | base64 -d
```

### Enable Backups

Configure backup storage in `additional_values`:

```hcl
additional_values = <<-EOT
  global:
    backup:
      enabled: true
      schedule: "0 2 * * *"
      upload:
        connection:
          secret: gitlab-backup-storage
          key: config
EOT
```

## Monitoring

If Prometheus and Grafana are enabled:

```bash
# Port-forward Prometheus
kubectl port-forward -n gitlab svc/gitlab-prometheus-server 9090:80

# Port-forward Grafana
kubectl port-forward -n gitlab svc/gitlab-grafana 3000:80
```

## Scaling

Adjust resources in `terraform.tfvars` and reapply:

```bash
terraform apply
```

## Troubleshooting

### Pods not starting

```bash
kubectl get pods -n gitlab
kubectl describe pod <pod-name> -n gitlab
kubectl logs <pod-name> -n gitlab
```

### Check architecture

```bash
# Verify cluster has amd64 nodes
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'

# Check pod placement
kubectl get pods -n gitlab -o wide
```

### Ingress issues

```bash
kubectl get ingress -n gitlab
kubectl describe ingress -n gitlab
```

## Cleanup

```bash
terraform destroy
```

**Warning:** This will delete all GitLab data including repositories and configurations.
