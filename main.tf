resource "kubernetes_namespace" "gitlab" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      name                     = var.namespace
      "app.kubernetes.io/name" = "gitlab"
    }
  }
}

# Local values for Helm chart configuration
locals {
  # Base node selector with architecture
  base_node_selector = merge(
    {
      "kubernetes.io/arch" = var.architecture
    },
    var.node_selector
  )

  # Default Helm values
  default_values = {
    global = {
      hosts = {
        domain = var.domain
      }
      ingress = {
        enabled              = true
        configureCertmanager = var.enable_certmanager
        class                = var.ingress_class
      }
      email = {
        from    = "gitlab@${var.domain}"
        replyTo = var.email
      }
      nodeSelector = local.base_node_selector
      tolerations  = var.tolerations
      psql = var.postgresql_password != "" ? {
        password = {
          secret = kubernetes_secret.gitlab_postgresql[0].metadata[0].name
          key    = "password"
        }
      } : {}
      redis = var.redis_password != "" ? {
        password = {
          secret = kubernetes_secret.gitlab_redis[0].metadata[0].name
          key    = "password"
        }
      } : {}
    }

    certmanager-issuer = var.enable_certmanager ? {
      email = var.email
    } : {}

    prometheus = {
      install = var.enable_prometheus
    }

    grafana = {
      enabled = var.enable_grafana
    }

    postgresql = {
      persistence = {
        storageClass = var.storage_class
      }
    }

    redis = {
      master = {
        persistence = {
          storageClass = var.storage_class
        }
      }
    }

    gitlab = {
      webservice = {
        resources = try(var.resources.webservice, {})
      }
      sidekiq = {
        resources = try(var.resources.sidekiq, {})
      }
    }
  }

  # Convert to YAML and merge with additional values
  helm_values = var.additional_values != "" ? [
    yamlencode(local.default_values),
    var.additional_values
    ] : [
    yamlencode(local.default_values)
  ]
}

# Secret for GitLab root password
resource "kubernetes_secret" "gitlab_root_password" {
  count = var.gitlab_root_password != "" ? 1 : 0

  metadata {
    name      = "${var.release_name}-root-password"
    namespace = var.create_namespace ? kubernetes_namespace.gitlab[0].metadata[0].name : var.namespace
  }

  data = {
    password = var.gitlab_root_password
  }

  type = "Opaque"
}

# Secret for PostgreSQL password
resource "kubernetes_secret" "gitlab_postgresql" {
  count = var.postgresql_password != "" ? 1 : 0

  metadata {
    name      = "${var.release_name}-postgresql-password"
    namespace = var.create_namespace ? kubernetes_namespace.gitlab[0].metadata[0].name : var.namespace
  }

  data = {
    password = var.postgresql_password
  }

  type = "Opaque"
}

# Secret for Redis password
resource "kubernetes_secret" "gitlab_redis" {
  count = var.redis_password != "" ? 1 : 0

  metadata {
    name      = "${var.release_name}-redis-password"
    namespace = var.create_namespace ? kubernetes_namespace.gitlab[0].metadata[0].name : var.namespace
  }

  data = {
    password = var.redis_password
  }

  type = "Opaque"
}

# GitLab Helm release
resource "helm_release" "gitlab" {
  name       = var.release_name
  repository = var.chart_repository
  chart      = "gitlab"
  version    = var.chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.gitlab[0].metadata[0].name : var.namespace

  values = local.helm_values

  timeout = var.timeout
  atomic  = var.atomic
  wait    = var.wait

  depends_on = [
    kubernetes_namespace.gitlab,
    kubernetes_secret.gitlab_root_password,
    kubernetes_secret.gitlab_postgresql,
    kubernetes_secret.gitlab_redis
  ]
}
