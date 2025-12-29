# GitLab ARM64 Deployment Example

This example deploys GitLab on arm64 (aarch64) architecture nodes. The configuration is generic and can be customized for different use cases (development, staging, production) and cloud providers.

## Prerequisites

- Kubernetes cluster with arm64 nodes
- kubectl configured to access the cluster
- Helm 3.x installed
- Ingress controller deployed (nginx, traefik, etc.)
- DNS configured to point your domain to the ingress

## Supported Platforms

- **AWS EKS (Graviton)**: t4g/c6g/c7g/m6g/m7g instance families
- **Google Cloud GKE (Tau T2A)**: t2a machine family (Ampere Altra)
- **Oracle Cloud Infrastructure**: VM.Standard.A1.Flex (Ampere Altra)
- **Azure AKS (Ampere)**: Dpsv5/Dplsv5 VM series
- **Equinix Metal**: c3.large.arm64 (Ampere Altra)
- **Local Kubernetes**: k3s on Raspberry Pi, ARM servers

## ARM64 Advantages

- **Cost savings**: 20-40% cheaper than equivalent amd64 instances
- **Energy efficiency**: Lower power consumption
- **Performance**: Competitive or better performance for many workloads
- **Memory bandwidth**: Often higher than x86_64

## Quick Start

1. **Verify cluster has arm64 nodes:**
   ```bash
   kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'
   # Should show: arm64
   ```

2. **Copy and customize configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Deploy:**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Get credentials:**
   ```bash
   kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
     -o jsonpath='{.data.password}' | base64 -d
   ```

6. **Access GitLab:**
   - URL: https://gitlab.example.com (your configured domain)
   - Username: `root`
   - Password: from step 5

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
storage_class = "pd-ssd"

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

### AWS EKS (Graviton2/Graviton3)

```hcl
storage_class = "gp3"

node_selector = {
  "node.kubernetes.io/instance-type" = "t4g.xlarge"  # or c6g.2xlarge, m6g.2xlarge
}
```

**Recommended instances:**
- Development: t4g.medium, t4g.large
- Production: c7g.2xlarge, m7g.2xlarge (latest generation)

### Google Cloud GKE (Tau T2A)

```hcl
storage_class = "pd-balanced"

node_selector = {
  "cloud.google.com/machine-family" = "t2a"
}
```

**Note:** T2A instances provide excellent price/performance for GitLab workloads.

### Oracle Cloud Infrastructure (Ampere Altra)

```hcl
storage_class = "oci-bv"

node_selector = {
  "node.kubernetes.io/instance-type" = "VM.Standard.A1.Flex"
}
```

**Note:** OCI offers generous free tier with A1 instances (4 OCPU, 24GB RAM always free).

### Azure AKS (Ampere Altra)

```hcl
storage_class = "managed-premium"

node_selector = {
  "kubernetes.azure.com/agentpool" = "gitlab"
}
```

## ARM64-Specific Considerations

### Image Compatibility

GitLab official images support multi-architecture (amd64/arm64). Verify:

```bash
docker manifest inspect registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee:latest
```

### CI/CD Pipelines

Ensure your CI/CD jobs use arm64-compatible images or enable cross-compilation:

```yaml
# .gitlab-ci.yml
default:
  image: ubuntu:22.04  # Multi-arch image

build:
  script:
    - uname -m  # Verify architecture (should show: aarch64)
    - # Your build commands
```

### Cross-Architecture Builds

For building multi-architecture images:

```yaml
# .gitlab-ci.yml
build-multiarch:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker buildx create --use
    - docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest --push .
```

### GitLab Runner Configuration

Configure runners to use arm64 by default:

```hcl
additional_values = <<-EOT
  gitlab-runner:
    runners:
      config: |
        [[runners]]
          [runners.kubernetes]
            image = "ubuntu:22.04"
            [[runners.kubernetes.node_selector]]
              "kubernetes.io/arch" = "arm64"
EOT
```

## Mixed-Architecture Clusters

If your cluster has both amd64 and arm64 nodes, use tolerations:

```hcl
tolerations = [
  {
    key      = "arch"
    operator = "Equal"
    value    = "arm64"
    effect   = "NoSchedule"
  }
]
```

This ensures GitLab pods only run on arm64 nodes.

## Performance Tuning

ARM64 platforms often have different performance characteristics:

- **Higher memory bandwidth**: Increase memory-intensive workloads
- **More cores available**: Graviton3 instances offer high core counts
- **Lower latency**: Better single-threaded performance on newer generations

Adjust resources based on monitoring data.

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

```bash
# Get runner registration token
kubectl get secret gitlab-gitlab-runner-secret -n gitlab \
  -o jsonpath='{.data.runner-registration-token}' | base64 -d
```

### Enable Backups

```hcl
additional_values = <<-EOT
  global:
    backup:
      enabled: true
      schedule: "0 2 * * *"
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

## Troubleshooting

### Verify architecture

```bash
# Check cluster nodes
kubectl get nodes -L kubernetes.io/arch

# Check pod placement
kubectl get pods -n gitlab -o wide

# Verify pod is on arm64 node
kubectl get pod <pod-name> -n gitlab -o jsonpath='{.spec.nodeSelector}'
```

### Image pull errors

If you see `exec format error`, the image doesn't support arm64:

```bash
kubectl describe pod <pod-name> -n gitlab
```

Solution: Update image to multi-arch version or arm64-specific image.

### Performance issues

```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods -n gitlab

# Check node capacity
kubectl describe node <arm64-node>
```

## Cost Comparison

Example monthly costs (AWS us-east-1, 3 nodes):

| Instance Type | Architecture | Monthly Cost | Performance |
|--------------|--------------|--------------|-------------|
| 3x t3.xlarge | amd64 | ~$450 | Baseline |
| 3x t4g.xlarge | arm64 (Graviton2) | ~$270 | Similar |
| 3x c7g.xlarge | arm64 (Graviton3) | ~$290 | +40% better |

**Savings:** 30-40% with comparable or better performance.

## Cleanup

```bash
terraform destroy
```

**Warning:** This will delete all GitLab data including repositories and configurations.
