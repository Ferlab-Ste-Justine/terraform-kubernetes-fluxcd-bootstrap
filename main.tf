locals {
  use_https = var.git_https_credentials != null
}

check "git_auth_mode" {
  assert {
    condition     = local.use_https != (var.git_identity != null)
    error_message = "Exactly one of git_identity/git_known_hosts or git_https_credentials must be provided."
  }
}

resource "kubernetes_namespace_v1" "fluxcd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.fluxcd_namespace.name
    labels = var.fluxcd_namespace.labels
  }
}

resource "kubernetes_secret_v1" "git_trusted_keys" {
  count = length(var.git_trusted_keys) > 0 ? 1 : 0

  metadata {
    name      = "${var.fluxcd_resources_name}-trusted-keys"
    namespace = var.fluxcd_namespace.name
  }

  data = {
    for idx, key in var.git_trusted_keys : "key${idx}.asc" => key
  }

  depends_on = [kubernetes_namespace_v1.fluxcd]
}

resource "kubernetes_secret_v1" "git_ssh_key" {
  count = local.use_https ? 0 : 1

  metadata {
    name      = "${var.fluxcd_resources_name}-key"
    namespace = var.fluxcd_namespace.name
  }

  data = {
    identity    = var.git_identity
    known_hosts = var.git_known_hosts
  }

  depends_on = [kubernetes_namespace_v1.fluxcd]
}

resource "kubernetes_secret_v1" "git_https_key" {
  count = local.use_https ? 1 : 0

  metadata {
    name      = "${var.fluxcd_resources_name}-key"
    namespace = var.fluxcd_namespace.name
  }

  data = {
    username = var.git_https_credentials.username
    password = var.git_https_credentials.password
  }

  depends_on = [kubernetes_namespace_v1.fluxcd]
}

resource "kubernetes_manifest" "gitrepository" {
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = var.fluxcd_resources_name
      namespace = var.fluxcd_namespace.name
    }
    spec = merge(
      {
        interval          = "1m"
        url               = var.repo_url
        recurseSubmodules = var.repo_recurse_submodules
        ref               = { branch = var.repo_branch }
        secretRef = {
          name = local.use_https ? kubernetes_secret_v1.git_https_key[0].metadata[0].name : kubernetes_secret_v1.git_ssh_key[0].metadata[0].name
        }
      },
      length(var.git_trusted_keys) > 0 ? {
        verify = {
          mode      = "head"
          secretRef = { name = kubernetes_secret_v1.git_trusted_keys[0].metadata[0].name }
        }
      } : {}
    )
  }

  depends_on = [
    kubernetes_secret_v1.git_ssh_key,
    kubernetes_secret_v1.git_https_key,
    kubernetes_secret_v1.git_trusted_keys,
  ]
}

resource "kubernetes_manifest" "kustomization" {
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = var.fluxcd_resources_name
      namespace = var.fluxcd_namespace.name
    }
    spec = {
      interval  = "1m"
      prune     = true
      path      = var.repo_path
      sourceRef = {
        kind = "GitRepository"
        name = var.fluxcd_resources_name
      }
    }
  }

  depends_on = [kubernetes_manifest.gitrepository]
}
