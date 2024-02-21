# Infrastructure

While the application can be deployed manually to GCP, this project includes:
- a [Terraform](https://www.terraform.io/) project that you can use to easily and quickly provision the resources and deploy the code using [Google Cloud Platform](https://cloud.google.com/),
- and a GH Actions workflow to deploy code updates.

## Dependencies

Below is the list of technical dependencies for this particular platform and deployment strategy:

- [Google Cloud Platform](https://cloud.google.com) and [gcloud CLI tool](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://www.terraform.io/)
- [GitHub](https://github.com)
- [GitHub Actions](https://github.com/features/actions)
- DNS management
- A purchased domain

## Infrastructure project files

There are 2 terraform projects in the infrastructure directory, placed in subdirectories:
1. remote-state
2. base - depends on remote-state

Also, there is a GH Actions workflow file in the `.github` directory in the top-level project directory.

### Terraform

#### Remote state

Creates a [GCP Storage Bucket](https://cloud.google.com/storage/docs/json_api/v1/buckets), which will store the Terraform remote state.

#### Base

Contains multiple GCP resources needed for running the Trase API shi, on GCP:

- Cloud Functions, one for each legacy API endpoint
- Networking resources - a load balancer which forwards traffic to the functions
- Error reporting
- Service accounts and permissions
- GH Secrets

To apply this project, you will need the following GCP permissions. These could probably be further fleshed out to a more restrictive set of permissions/roles, but this combination is know to work:

- "Editor" role
- "Secret Manager Admin" role
- "Cloud Run Admin" role
- "Compute Network Admin" role
- "Security Admin" role

The output values include access data for some of the resources above.

#### How to run

##### Prerequisites

1. Ensure you have the `gcloud` cli tool installed. Authenticate with GCP:

`gcloud auth application-default login`

2. Ensure you have `terraform` installed and matching the version specified in `remote-state/versions.tf` and `base/versions.tf` (`terraform -> required_version`). It is easiest to use `tfswitch` to install required versions.

3. Generate a GitHub token to be able to set GH Actions Secrets and Variables in the repository where the GH Actions workflow will run.

##### Initialise and apply the `remote-state` project

This needs to be done only once. It creates storage for terraform state used by the `base` project.

- `cd` in the `remote-state` directory
- `terraform init`
- create a file in `remote-state/vars/terraform.tfvars` with the following settings:
    ```
    gcp_region     = "YOUR GCP REGION"
    gcp_project_id = "YOUR GCP PROJECT ID"
    bucket_name    = "trase-api-tf-state"
    ```
- `terraform apply -var-file=vars/terraform.tfvars`

##### Initialise and deploy the `base` project

This needs to be repeated when there are changes to the infrastructure settings or the secrets / variables.

- `cd` in the `base` directory
- `terraform init`
- create a file in `base/vars/terraform.tfvars` with the following settings:
    ```
    gcp_region     = "YOUR GCP REGION"
    gcp_zone       = "YOUR GCP ZONE
    gcp_project_id = "YOUR GCP PROJECT ID"

    github_org     = "GH repository organisation
    github_project = "GH repository name"

    production_project_name = "trase-api-prod" # used for prefixing GCP resources

    domain = "YOUR DOMAIN e.g. example.com"
    production_subdomain = "trase-api" # the shim will be at trase-api.example.com

    bigquery_snapshot = "_2024-01-17_oxindole" # symbol of the BigQuery snapshot
    ```
- `GITHUB_TOKEN=... GITHUB_OWNER=.. terraform apply -var-file=vars/terraform.tfvars`

#### DNS changes

After the cloud functions and the load balancer are provisioned, an A type record needs to added to the DNS of the required domain to point to the load balancer's IP.

### GitHub Actions

As part of this infrastructure, GitHub Actions are used to automatically apply code updates for the client application, API/CMS and the cloud functions.

#### Building new code versions

Deployment to the cloud functions is accomplished by pushing the source code. Secrets and env vars required to authenticate and to deploy are set via Terraform.

That workflow requires the following GH Actions secrets to be set:

- `GCP_REGION`
- `GCP_PROJECT_ID`
- `[ENVIRONMENT]_GCP_SA_KEY` (currently only PRODUCTION) - credentials for the service account used for deployment

And the following GH Actions variables:
- `PRODUCTION_CONTEXTS_CF_NAME`
- `PRODUCTION_COLUMNS_CF_NAME`
- `PRODUCTION_NODES_CF_NAME`
- `PRODUCTION_TOP_NODES_CF_NAME`

The workflow is currently set up to deploy to the production instance when pushing / merging to `main` branch.

#### Service account permissions

Access by GitHub to GCP is configured through special authorization rules, automatically set up by the Terraform `base` project above.
These permissions are necessary for the service account that runs the deployment:
- "roles/iam.serviceAccountTokenCreator",
- "roles/iam.serviceAccountUser",
- "roles/run.developer",
- "roles/cloudfunctions.developer"
