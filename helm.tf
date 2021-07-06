resource "helm_release" "github_runner" {
  depends_on = [var.mod_dependency, kubernetes_namespace.github_runner]
  count      = var.enabled ? 1 : 0
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version
  namespace  = var.namespace

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.service_account_iam_role_arn != null ? var.service_account_iam_role_arn : aws_iam_role.github_runner[0].arn
  }

  set {
    name  = "authSecret.create"
    value = true
  }

  set {
    name  = "authSecret.github_app_id"
    value = var.github_app_app_id
  }

  set {
    name  = "authSecret.github_app_installation_id"
    value = var.github_app_installation_id
  }

  set {
    name  = "authSecret.github_app_private_key"
    value = var.github_app_private_key
  }

  set {
    name  = "authSecret.github_token"
    value = var.github_token
  }

  values = [
    yamlencode(var.settings)
  ]
}