module "github_runner" {
  source = "../../."

  enabled = true

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_id

  github_app_app_id          = "123"
  github_app_installation_id = "123"
  github_organizations = [
    {
      name     = "example_org"
      replicas = 1
      label    = "example_label"
    }
  ]
  github_repositories = [
    {
      name     = "example_repo"
      replicas = 1
      label    = "example_label"
    }
  ]
  policy_arns            = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  github_app_private_key = <<EOT
-----BEGIN RSA PRIVATE KEY-----
key
-----END RSA PRIVATE KEY-----
EOT

  depends_on = [module.eks]
}