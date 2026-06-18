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
  type        = string
  default     = "fluxcd"
}

variable "git_trusted_keys" {
  description = "List of public keys of all trusted git authors"
  type        = list(string)
  default     = []
}

variable "auth" {
  description = "Authentication parameters that the bootstrapping fluxcd gitrepository resource will use with the remote git server"
  type = object({
    https = optional(object({
      username = string
      password = string
    }))
    ssh = optional(object({
      key         = string
      known_hosts = optional(string)
    }))
  })

  validation {
    condition     = (var.auth.https != null) != (var.auth.ssh != null)
    error_message = "Exactly one of `auth.https` or `auth.ssh` must be defined (not both, not neither)."
  }
}

variable "repo_url" {
  description = "URL of the repo (SSH or HTTPS depending on the chosen auth mode)"
  type        = string
}

variable "repo_branch" {
  description = "Branch to use on the repo"
  type        = string
  default     = "main"
}

variable "repo_path" {
  description = "Path in the repo to run kustomize on"
  type        = string
  default     = "./"
}

variable "repo_recurse_submodules" {
  description = "Whether to clone the gitsubmodules of the repo"
  type        = bool
  default     = false
}
