resource "kubectl_manifest" "github_org_runners" {
  for_each  = { for org in var.github_organizations : org.name => org }
  yaml_body = <<YAML
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: ${lower(each.value.name)}-runner-deployment
  namespace: ${var.namespace}
spec:
  replicas: ${each.value.replicas}
  template:
    spec:
      organization: ${each.value.name}
      serviceAccountName: ${var.service_account_name}
      ephemeral: ${var.ephemeral_runner}
      securityContext:
        fsGroup: 1000
      labels:
        - ${each.value.label}
YAML

  depends_on = [helm_release.github_runner]
}