data "aws_iam_policy_document" "github_runner_assume" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_identity_oidc_issuer, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "github_runner" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-github-runner-controller"
  assume_role_policy = data.aws_iam_policy_document.github_runner_assume[0].json
}

resource "aws_iam_role_policy_attachment" "github_runner" {
  count      = var.enabled ? length(var.policy_arns) : 0
  role       = aws_iam_role.github_runner[0].name
  policy_arn = data.aws_iam_policy.github_runner[count.index].arn
}

data "aws_iam_policy" "github_runner" {
  count = var.enabled ? length(var.policy_arns) : 0

  arn = var.policy_arns[count.index]
}