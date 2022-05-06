# About

This Terraform module bootstraps fluxcd initial resources on a kubernetes cluster. It assumes that fluxcd is already installed (see: https://github.com/Ferlab-Ste-Justine/fluxcd-installation)

By the time the module has run, you will have:
- A GitRepo and Kustomize resource created for a repo. This repo may be used directly for all orchestrations or otherwise, further fluxcd resources pointing to downstream repos could be created in this repo.

# Usage

## Input

The module takes the following input variables:

- **fluxcd_namespace**: Namespace of the resources pointing to the root repo will exist in. Defaults to "flux".
- **fluxcd_resources_name**: Name to give to created resources. A **GitRepository**, **Kustomization**, and **ServiceAccount** resource will be created under the **fluxcd_namespace** namespace with that name. Additionally, a **ClusterRole** and **ClusterRoleBinding** resource will be created with the name ```<fluxcd_namespace>-<fluxcd_resources_name>```. And finally, two secrets named ```<fluxcd_resources_name>-key``` and ```<fluxcd_resources_name>-trusted-keys``` (the later is optional) will be created in the **fluxcd_namespace** namespace.
- **git_identity**: Git ssh key to access repo
- **git_known_hosts**: Git host fingerprint, in the format expected by fluxcd
- **git_trusted_keys**: An optional concatenated public keys of all trusted git authors. If defined, fluxcd will only deploy if the head commit in the specified repo branch is signed by one of the trusted authors.
- **repo_url**: Ssh url of the repo
- **repo_branch**: Branch to clone in the repo. Defaults to "main".
- **repo_path**: Path in the repo containing the kustomization or ortherwise the manifest files. Defaults to the root of the repo.
- **repo_recurse_submodules**: If set to true, git submodules will be recursed in the repo. Defaults to false.

## Example

```
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

module "flux_installation" {
  source = "git::https://github.com/Ferlab-Ste-Justine/fluxcd-installation.git"
}

module "flux_bootstrap" {
  source = "git::https://github.com/Ferlab-Ste-Justine/fluxcd-bootstrap.git"
  git_identity = tls_private_key.root_orchestration_repo.private_key_pem
  git_known_hosts = "github.com ssh-rsa <look it up>"
  repo_url = "ssh://git@github.com:22/my-org/my-repo.git"
  repo_path = "some-path-in-repo"
  depends_on = [module.flux_installation]
}
```

## Dependencies

This repo is dependent on the following providers being defined and pointing to your kubernetes cluster:
- hashicorp/kubernetes
- gavinbunney/kubectl