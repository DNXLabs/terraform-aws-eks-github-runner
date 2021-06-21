# terraform-aws-eks-github-runner

[![Lint Status](https://github.com/DNXLabs/terraform-aws-eks-github-runner/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-eks-github-runner/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-eks-github-runner)](https://github.com/DNXLabs/terraform-aws-eks-github-runner/blob/master/LICENSE)

Terraform module for deploying [GitHub Actions Runner Operator](https://github.com/evryfs/github-actions-runner-operator) inside a pre-existing EKS cluster.


## Setting Up Authentication with GitHub API

There are two ways for actions-runner-controller to authenticate with the GitHub API (only 1 can be configured at a time however):

1. Using a GitHub App (not supported for enterprise level runners due to lack of support from GitHub)
2. Using a PAT

Functionality wise, there isn't much of a difference between the 2 authentication methods. The primarily benefit of authenticating via a GitHub App is an [increased API quota](https://docs.github.com/en/developers/apps/rate-limits-for-github-apps).

If you are deploying the solution for a GitHub Enterprise Server environment you are able to [configure your rate limiting settings](https://docs.github.com/en/enterprise-server@3.0/admin/configuration/configuring-rate-limits) making the main benefit irrelevant. If you're deploying the solution for a GitHub Enterprise Cloud or regular GitHub environment and you run into rate limiting issues, consider deploying the solution using the GitHub App authentication method instead.

### Deploying Using GitHub App Authentication

You can create a GitHub App for either your user account or any organization, below are the app permissions required for each supported type of runner:

_Note: Links are provided further down to create an app for your logged in user account or an organisation with the permissions for all runner types set in each link's query string_

**Required Permissions for Repository Runners:**<br />
**Repository Permissions**

* Actions (read)
* Administration (read / write)
* Metadata (read)

**Required Permissions for Organisation Runners:**<br />
**Repository Permissions**

* Actions (read)
* Metadata (read)

**Organization Permissions**
* Self-hosted runners (read / write)

_Note: All API routes mapped to their permissions can be found [here](https://docs.github.com/en/rest/reference/permissions-required-for-github-apps) if you wish to review_

---

**Setup Steps**

If you want to create a GitHub App for your account, open the following link to the creation page, enter any unique name in the "GitHub App name" field, and hit the "Create GitHub App" button at the bottom of the page.

- [Create GitHub Apps on your account](https://github.com/settings/apps/new?url=http://github.com/actions-runner-controller/actions-runner-controller&webhook_active=false&public=false&administration=write&actions=read)

If you want to create a GitHub App for your organization, replace the `:org` part of the following URL with your organization name before opening it. Then enter any unique name in the "GitHub App name" field, and hit the "Create GitHub App" button at the bottom of the page to create a GitHub App.

- [Create GitHub Apps on your organization](https://github.com/organizations/:org/settings/apps/new?url=http://github.com/actions-runner-controller/actions-runner-controller&webhook_active=false&public=false&administration=write&organization_self_hosted_runners=write&actions=read)

You will see an *App ID* on the page of the GitHub App you created as follows, the value of this App ID will be used later.

<img width="750" alt="App ID" src="images/app_id.png">

Download the private key file by pushing the "Generate a private key" button at the bottom of the GitHub App page. This file will also be used later.

<img width="750" alt="Generate a private key" src="images/private_keys.png">

Go to the "Install App" tab on the left side of the page and install the GitHub App that you created for your account or organization.

<img width="750" alt="Install App" src="images/install_app.png">

When the installation is complete, you will be taken to a URL in one of the following formats, the last number of the URL will be used as the Installation ID later (For example, if the URL ends in `settings/installations/12345`, then the Installation ID is `12345`).

- `https://github.com/settings/installations/${INSTALLATION_ID}`
- `https://github.com/organizations/eventreactor/settings/installations/${INSTALLATION_ID}`


Finally, register the App ID (`APP_ID`), Installation ID (`INSTALLATION_ID`), and downloaded private key file (`PRIVATE_KEY_FILE_PATH`) to Kubernetes as Secret.


### Deploying Using PAT Authentication

Personal Access Tokens can be used to register a self-hosted runner by *actions-runner-controller*.

Log-in to a GitHub account that has `admin` privileges for the repository, and [create a personal access token](https://github.com/settings/tokens/new) with the appropriate scopes listed below:

**Required Scopes for Repository Runners**

* repo (Full control)

**Required Scopes for Organization Runners**

* repo (Full control)
* admin:org (Full control)
* admin:public_key (read:public_key)
* admin:repo_hook (read:repo_hook)
* admin:org_hook (Full control)
* notifications (Full control)
* workflow (Full control)


## Usage

```
module "github_runner" {
  source  = "DNXLabs/eks-github-runner/aws"
  version = "0.1.0"

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  github_app_app_id          = "123"
  github_app_installation_id = "123"
  github_organizations       = [
    {
      name     = "example_org"
      replicas = 1
      label    = "example_label"
    }
  ]
  github_repositories        = [
    {
      name     = "example_repo"
      replicas = 1
      label    = "example_label"
    }
  ]
  policy_arns                = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  github_app_private_key     = <<EOT
-----BEGIN RSA PRIVATE KEY-----
<key>
-----END RSA PRIVATE KEY-----
EOT

}
```

[GitHub self-hosted runners can be deployed at various levels in a management hierarchy](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#about-self-hosted-runners):
- The repository level
- The organization level

There are two ways to use this controller:

- Manage runners one by one with `Runner`.
- Manage a set of runners with `RunnerDeployment`.

### Manual Deploy Repository Runners

To launch a single self-hosted runner, you need to create a manifest file includes `Runner` resource as follows. This example launches a self-hosted runner with name *example-runner* for the *actions-runner-controller/actions-runner-controller* repository.

```yaml
# runner.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: Runner
metadata:
  name: example-runner
spec:
  repository: summerwind/actions-runner-controller
  env: []
```

Apply the created manifest file to your Kubernetes.

```shell
$ kubectl apply -f runner.yaml
runner.actions.summerwind.dev/example-runner created
```

You can see that the Runner resource has been created.

```shell
$ kubectl get runners
NAME             REPOSITORY                             STATUS
example-runner   summerwind/actions-runner-controller   Running
```

You can also see that the runner pod has been running.

```shell
$ kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
example-runner 2/2     Running   0          1m
```

The runner you created has been registered to your repository.

<img width="756" alt="Actions tab in your repository settings" src="images/self_hosted_interface.png">

Now you can use your self-hosted runner. See the [official documentation](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/using-self-hosted-runners-in-a-workflow) on how to run a job with it.

### Manual Deploy Organization Runners

To add the runner to an organization, you only need to replace the `repository` field with `organization`, so the runner will register itself to the organization.

```yaml
# runner.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: Runner
metadata:
  name: example-org-runner
spec:
  organization: your-organization-name
```

Now you can see the runner on the organization level (if you have organization owner permissions).

### RunnerDeployments

There are `RunnerReplicaSet` and `RunnerDeployment` that corresponds to `ReplicaSet` and `Deployment` but for `Runner`.

You usually need only `RunnerDeployment` rather than `RunnerReplicaSet` as the former is for managing the latter.

```yaml
# runnerdeployment.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: example-runnerdeploy
spec:
  replicas: 2
  template:
    spec:
      repository: mumoshu/actions-runner-controller-ci
      env: []
```

Apply the manifest file to your cluster:

```shell
$ kubectl apply -f runnerdeployment.yaml
runnerdeployment.actions.summerwind.dev/example-runnerdeploy created
```

You can see that 2 runners have been created as specified by `replicas: 2`:

```shell
$ kubectl get runners
NAME                             REPOSITORY                             STATUS
example-runnerdeploy2475h595fr   mumoshu/actions-runner-controller-ci   Running
example-runnerdeploy2475ht2qbr   mumoshu/actions-runner-controller-ci   Running
```

### Runner Labels

To run a workflow job on a self-hosted runner, you can use the following syntax in your workflow:

```yaml
jobs:
  release:
    runs-on: self-hosted
```

When you have multiple kinds of self-hosted runners, you can distinguish between them using labels. In order to do so, you can specify one or more labels in your `Runner` or `RunnerDeployment` spec.

```yaml
# runnerdeployment.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: custom-runner
spec:
  replicas: 1
  template:
    spec:
      repository: summerwind/actions-runner-controller
      labels:
        - custom-runner
```

Once this spec is applied, you can observe the labels for your runner from the repository or organization in the GitHub settings page for the repository or organization. You can now select a specific runner from your workflow by using the label in `runs-on`:

```yaml
jobs:
  release:
    runs-on: custom-runner
```

Note that if you specify `self-hosted` in your workflow, then this will run your job on _any_ self-hosted runner, regardless of the labels that they have.

### Runner Groups

Runner groups can be used to limit which repositories are able to use the GitHub Runner at an organization level. Runner groups have to be [created in GitHub first](https://docs.github.com/en/actions/hosting-your-own-runners/managing-access-to-self-hosted-runners-using-groups) before they can be referenced.

To add the runner to the group `NewGroup`, specify the group in your `Runner` or `RunnerDeployment` spec.

```yaml
# runnerdeployment.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: custom-runner
spec:
  replicas: 1
  template:
    spec:
      group: NewGroup
```

### Using IRSA (IAM Roles for Service Accounts) in EKS

`actions-runner-controller` v0.15.0 or later has support for IRSA in EKS.

As similar as for regular pods and deployments, you firstly need an existing service account with the IAM role associated.
Create one using e.g. `eksctl`. You can refer to [the EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for more details.

Once you set up the service account, all you need is to add `serviceAccountName` and `fsGroup` to any pods that uses the IAM-role enabled service account.

For `RunnerDeployment`, you can set those two fields under the runner spec at `RunnerDeployment.Spec.Template`:

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: example-runnerdeploy
spec:
  template:
    spec:
      repository: USER/REO
      serviceAccountName: my-service-account
      securityContext:
        fsGroup: 1000
```

<!--- BEGIN_TF_DOCS --->


<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-eks-github-runner/blob/master/LICENSE) for full details.