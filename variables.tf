variable "fluxcd_namespace" {
  description = "Namespace where FluxCD resources (GitRepository, Kustomization, Secrets) will be created. Distinct from the system namespace where FluxCD controllers run."
  type = object({
    name   = string
    labels = map(string)
  })
  default = {
    name   = "fluxcd"
    labels = {}
  }
}

variable "create_namespace" {
  description = "Whether to create the FluxCD resources namespace. Set to false when the namespace is managed externally."
  type        = bool
  default     = true
}

variable "fluxcd_resources_name" {
  description = "Name to give to generated bootstrap resources"
  type = string
  default = "fluxcd"
}

variable "git_trusted_keys" {
  description = "List of public keys of all trusted git authors"
  type = list(string)
  default = []
}

variable "git_identity" {
  description = "Git SSH private key to access repo. Required when git_https_credentials is not set."
  type    = string
  default = null
}

variable "git_known_hosts" {
  description = "Git host fingerprint, in the format expected by FluxCD. Required when git_https_credentials is not set."
  type    = string
  default = null
}

variable "git_https_credentials" {
  description = "HTTPS credentials for git access (username + password/PAT). Mutually exclusive with git_identity/git_known_hosts."
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "repo_url" {
  description = "Url of the repo"
  type = string
}

variable "repo_branch" {
  description = "Branch to use on the repo"
  type = string
  default = "main"
}

variable "repo_path" {
  description = "Path in the repo to run kustomize on"
  type = string
  default = "./"
}

variable "repo_recurse_submodules" {
  description = "Whether to clone the gitsubmodules of the repo"
  type = bool
  default = false
}
