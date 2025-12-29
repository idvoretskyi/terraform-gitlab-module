# Terraform GitLab Kubernetes Module

A Terraform module for deploying GitLab to Kubernetes clusters with multi-architecture support (amd64 and arm64).

## Features

- **Multi-Architecture Support**: Deploy on amd64 or arm64 nodes with automatic node selection
- **Helm-Based Deployment**: Uses official GitLab Helm chart
- **Flexible Configuration**: Extensive customization via variables and Helm values
- **Production-Ready**: Includes monitoring, backups, and HA configurations
- **Mixed-Architecture Clusters**: Support for clusters with both amd64 and arm64 nodes
- **Secret Management**: Secure handling of credentials via Kubernetes secrets

## Quick Start

### Minimal Deployment

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain = "gitlab.example.com"
  email  = "admin@example.com"

  architecture = "amd64"  # or "arm64"
}
```

### Production Deployment

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain       = "gitlab.example.com"
  email        = "admin@example.com"
  architecture = "arm64"

  storage_class = "fast-ssd"

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

  enable_prometheus  = true
  enable_grafana     = true
  enable_certmanager = true
}
```

## Architecture Support

This module automatically handles architecture-specific deployments:

- **amd64**: Standard x86_64 architecture (Intel/AMD)
- **arm64**: ARM 64-bit architecture (AWS Graviton, Oracle ARM, Ampere Altra)

The module sets `kubernetes.io/arch` node selector to ensure all GitLab components run on the correct architecture.

## Examples

- **[amd64](examples/amd64/)**: GitLab deployment on amd64 (x86_64) architecture - supports AWS, GCP, Azure, and local clusters
- **[arm64](examples/arm64/)**: GitLab deployment on arm64 (aarch64) architecture - supports AWS Graviton, GCP Tau T2A, Oracle ARM, and Azure Ampere

Both examples are fully generic and can be customized for development, staging, or production environments.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | ~> 2.12 |
| kubernetes | ~> 2.25 |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 2.12 |
| kubernetes | ~> 2.25 |

## Resources

| Type | Name |
|------|------|
| kubernetes_namespace | gitlab |
| kubernetes_secret | gitlab_root_password |
| kubernetes_secret | gitlab_postgresql |
| kubernetes_secret | gitlab_redis |
| helm_release | gitlab |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain | Base domain for GitLab | `string` | n/a | yes |
| email | Email for Let's Encrypt certificates | `string` | n/a | yes |
| architecture | Target architecture (amd64 or arm64) | `string` | `"amd64"` | no |
| namespace | Kubernetes namespace | `string` | `"gitlab"` | no |
| create_namespace | Create namespace if doesn't exist | `bool` | `true` | no |
| release_name | Helm release name | `string` | `"gitlab"` | no |
| chart_version | GitLab Helm chart version | `string` | `"7.7.0"` | no |
| storage_class | Storage class for PVs | `string` | `"standard"` | no |
| enable_certmanager | Enable cert-manager | `bool` | `true` | no |
| enable_prometheus | Enable Prometheus | `bool` | `true` | no |
| enable_grafana | Enable Grafana | `bool` | `true` | no |
| node_selector | Additional node selectors | `map(string)` | `{}` | no |
| tolerations | Pod tolerations | `list(object)` | `[]` | no |
| resources | Resource requests/limits | `object` | `{}` | no |
| additional_values | Additional Helm values (YAML) | `string` | `""` | no |

See [variables.tf](variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| namespace | Deployment namespace |
| release_name | Helm release name |
| release_version | Deployed chart version |
| gitlab_url | GitLab URL |
| registry_url | Container registry URL |
| architecture | Target architecture |
| node_selector | Applied node selector |

## Usage with Different Cloud Providers

### AWS EKS (Graviton)

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain       = "gitlab.example.com"
  email        = "admin@example.com"
  architecture = "arm64"

  storage_class = "gp3"

  node_selector = {
    "node.kubernetes.io/instance-type" = "t4g.xlarge"
  }
}
```

### Google Cloud GKE (Tau T2A)

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain       = "gitlab.example.com"
  email        = "admin@example.com"
  architecture = "arm64"

  storage_class = "pd-ssd"

  node_selector = {
    "cloud.google.com/machine-family" = "t2a"
  }
}
```

### Oracle Cloud Infrastructure (Ampere)

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain       = "gitlab.example.com"
  email        = "admin@example.com"
  architecture = "arm64"

  storage_class = "oci-bv"

  node_selector = {
    "node.kubernetes.io/instance-type" = "VM.Standard.A1.Flex"
  }
}
```

## Post-Deployment

### Get GitLab Root Password

```bash
kubectl get secret <release-name>-gitlab-initial-root-password \
  -n <namespace> -o jsonpath='{.data.password}' | base64 -d
```

### Access GitLab

```
URL: https://gitlab.<your-domain>
Username: root
Password: <from above command>
```

### Monitor Deployment

```bash
kubectl get pods -n <namespace> -w
helm list -n <namespace>
```

## Advanced Configuration

### Custom Helm Values

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain       = "gitlab.example.com"
  email        = "admin@example.com"
  architecture = "arm64"

  additional_values = yamlencode({
    global = {
      backup = {
        enabled  = true
        schedule = "0 2 * * *"
      }
    }
    gitlab-runner = {
      runners = {
        config = <<-EOT
          [[runners]]
            [runners.kubernetes]
              image = "ubuntu:22.04"
        EOT
      }
    }
  })
}
```

### Secure Secrets

```hcl
module "gitlab" {
  source = "github.com/idvoretskyi/terraform-gitlab-module"

  domain = "gitlab.example.com"
  email  = "admin@example.com"

  gitlab_root_password = var.gitlab_root_password  # From Terraform variables
  postgresql_password  = var.postgresql_password
  redis_password       = var.redis_password
}
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development instructions and architecture documentation.

## License

MIT

## Maintainer

Igor Dvoretskyi ([@idvoretskyi](https://github.com/idvoretskyi))
