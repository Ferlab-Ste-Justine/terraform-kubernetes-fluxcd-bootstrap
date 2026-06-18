# About

This Terraform module bootstraps fluxcd initial resources on a kubernetes cluster. It assumes that fluxcd is already installed (see: https://github.com/Ferlab-Ste-Justine/fluxcd-installation)

By the time the module has run, you will have:
- A GitRepo and Kustomize resource created for a repo. This repo may be used directly for all orchestrations or otherwise, further fluxcd resources pointing to downstream repos could be created in this repo.

# Usage

## Input

The module takes the following input variables:

- **fluxcd_namespace**: Object describing the namespace for bootstrap resources (name + optional labels). Defaults to name "fluxcd" with empty labels.
- **fluxcd_resources_name**: Name to give to created resources. A **GitRepository**, **Kustomization**, and a secret named ```<fluxcd_resources_name>-key``` will be created under the **fluxcd_namespace** namespace. An optional ```<fluxcd_resources_name>-trusted-keys``` secret is also created when **git_trusted_keys** is set.
- **git_identity**: Git SSH private key to access repo. Required when **git_https_credentials** is not set.
- **git_known_hosts**: Git host fingerprint, in the format expected by FluxCD. Required when **git_https_credentials** is not set.
- **git_https_credentials**: Object with **username** and **password** fields for HTTPS git access. Mutually exclusive with **git_identity**/**git_known_hosts**. Use this when SSH ports are not reachable.
- **git_trusted_keys**: An optional concatenated public keys of all trusted git authors. If defined, fluxcd will only deploy if the head commit in the specified repo branch is signed by one of the trusted authors.
- **repo_url**: URL of the repo (SSH or HTTPS depending on the chosen auth mode).
- **repo_branch**: Branch to clone in the repo. Defaults to "main".
- **repo_path**: Path in the repo containing the kustomization or otherwise the manifest files. Defaults to the root of the repo.
- **repo_recurse_submodules**: If set to true, git submodules will be recursed in the repo. Defaults to false.

## Examples

### SSH authentication

```hcl
resource "tls_private_key" "root_orchestration_repo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "github_repository_deploy_key" "root_repo" {
  title      = "Fluxcd deploy key for some repo"
  repository = "my-repo"
  key        = tls_private_key.root_orchestration_repo.public_key_openssh
  read_only  = "false"
}

module "flux_bootstrap" {
  source = "git::https://github.com/Ferlab-Ste-Justine/terraform-kubernetes-fluxcd-bootstrap.git"
  fluxcd_namespace = {
    name   = "fluxcd"
    labels = {}
  }
  git_identity    = tls_private_key.root_orchestration_repo.private_key_pem
  git_known_hosts = "github.com ssh-rsa <look it up>"
  repo_url        = "ssh://git@github.com:22/my-org/my-repo.git"
  repo_path       = "some-path-in-repo"
}
```

### HTTPS authentication (when SSH ports are blocked)

```hcl
module "flux_bootstrap" {
  source = "git::https://github.com/Ferlab-Ste-Justine/terraform-kubernetes-fluxcd-bootstrap.git"
  fluxcd_namespace = {
    name   = "fluxcd"
    labels = {}
  }
  git_https_credentials = {
    username = "pat"
    password = var.azdo_pat
  }
  repo_url  = "https://dev.azure.com/my-org/my-project/_git/my-repo"
  repo_path = "some-path-in-repo"
}
```

## Dependencies

This repo is dependent on the following providers being defined and pointing to your kubernetes cluster:
- hashicorp/kubernetes
