variable "enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled."
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster."
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OIDC Identity issuer for the cluster."
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account."
}

variable "helm_chart_name" {
  type        = string
  default     = "actions-runner-controller"
  description = "GitHub Runner Controller Helm chart name."
}

variable "helm_chart_release_name" {
  type        = string
  default     = "actions-runner-controller"
  description = "GitHub Runner Controller Helm chart release name."
}

variable "helm_chart_repo" {
  type        = string
  default     = "https://actions-runner-controller.github.io/actions-runner-controller"
  description = "GitHub Runner Controller Helm repository name."
}

variable "helm_chart_version" {
  type        = string
  default     = "0.12.2"
  description = "GitHub Runner Controller Helm chart version."
}

variable "github_app_app_id" {
  type        = string
  description = "The ID of your GitHub App. This can't be set at the same time as `github_token`"
}

variable "github_app_installation_id" {
  type        = string
  description = "The ID of your GitHub App installation. This can't be set at the same time as `github_token`"
}

variable "github_app_private_key" {
  type        = string
  description = "The multiline string of your GitHub App's private key. This can't be set at the same time as `github_token`"
}

variable "github_token" {
  type        = string
  default     = ""
  description = "Your chosen GitHub PAT token. This can't be set at the same time as the `github_app_*`"
}

variable "github_organizations" {
  type = list(object({
    name     = string
    replicas = number
    label    = string
  }))
  default = []
}

variable "github_repositories" {
  type = list(object({
    name     = string
    replicas = number
    label    = string
  }))
  default = []
}

variable "policy_arns" {
  type    = list(string)
  default = []
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether to create Kubernetes namespace with name defined by `namespace`."
}

variable "namespace" {
  type        = string
  default     = "actions-runner-system"
  description = "GitHub Runner Controller Helm chart namespace which the service will be created."
}

variable "service_account_name" {
  type        = string
  default     = "github-actions-runner-controller"
  description = "GitHub runner service account name."
}

variable "mod_dependency" {
  default     = null
  description = "Dependence variable binds all AWS resources allocated by this module, dependent modules reference this variable."
}

variable "settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/actions-runner-controller/actions-runner-controller/blob/master/charts/actions-runner-controller/README.md"
}
