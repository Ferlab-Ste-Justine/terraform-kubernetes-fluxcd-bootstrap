locals {
  use_https   = var.auth.https != null
  secret_name = "${var.fluxcd_resources_name}-credentials"
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

resource "kubernetes_secret_v1" "git_ssh_credentials" {
  count = local.use_https ? 0 : 1

  metadata {
    name      = local.secret_name
    namespace = var.fluxcd_namespace.name
  }

  data = merge(
    { identity = var.auth.ssh.key },
    var.auth.ssh.known_hosts != null ? { known_hosts = var.auth.ssh.known_hosts } : {}
  )

  depends_on = [kubernetes_namespace_v1.fluxcd]
}

resource "kubernetes_secret_v1" "git_https_credentials" {
  count = local.use_https ? 1 : 0

  metadata {
    name      = local.secret_name
    namespace = var.fluxcd_namespace.name
  }

  data = {
    username = var.auth.https.username
    password = var.auth.https.password
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
        secretRef         = { name = local.secret_name }
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
    kubernetes_secret_v1.git_ssh_credentials,
    kubernetes_secret_v1.git_https_credentials,
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
