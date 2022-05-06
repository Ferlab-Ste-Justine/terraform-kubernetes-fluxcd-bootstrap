locals {
  bootstrap_repo_resources_values = split("---\n", templatefile(
    "${path.module}/bootstrap-repo-manifests/manifest-template.yml",
    {
      flux_namespace = var.fluxcd_namespace,
      flux_resources_name = var.fluxcd_name
      repo_url = var.repo_url,
      repo_branch = var.repo_branch
      repo_path = var.repo_path
      repo_recurse_submodules = var.repo_recurse_submodules
      trusted_keys_verification = var.git_trusted_keys != ""
    }
  ))
  bootstrap_repo_resources_keys = [for elem_outer in [for elem_inner in local.bootstrap_repo_resources_values: yamldecode(elem_inner)]: "${elem_outer.apiVersion}/${elem_outer.kind}/${lookup(elem_outer.metadata, "namespace", "default")}/${elem_outer.metadata.name}"]
  bootstrap_repo_resources = zipmap(local.bootstrap_repo_resources_keys, local.bootstrap_repo_resources_values)
}

resource "kubernetes_namespace" "fluxcd" {
  metadata {
    name = var.fluxcd_namespace
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

resource "kubernetes_secret" "git_trusted_keys"  {
  count = var.git_trusted_keys != "" ? 1 : 0
  metadata {
    namespace = var.fluxcd_namespace
    name =      "${var.fluxcd_name}-trusted-keys"
  }

  data = {
    "keys.asc" = var.git_trusted_keys
  }

  depends_on = [kubernetes_namespace.fluxcd]
}

resource "kubernetes_secret" "git_ssh_key" {
  metadata {
    namespace = var.fluxcd_namespace
    name =      "${var.fluxcd_name}-key"
  }

  data = {
    identity    = var.git_identity
    known_hosts = var.git_known_hosts
  }

  depends_on = [kubernetes_namespace.fluxcd]
}

resource "kubectl_manifest" "bootstrap_repo" {
  for_each   = local.bootstrap_repo_resources
  yaml_body  = each.value
}