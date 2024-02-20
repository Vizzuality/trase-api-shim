# Trase API shim
A connector for legacy Trase API clients, maps selected endpoints to current BigQuery implementation.

## Maintenance documentation

This repository contains all the code and documentation necessary to set up and deploy the project. It is organised in subdirectories, with accompanying documentation inside each.

| Subdirectory name | Description                                                 | Documentation                                                                                            |
|-------------------|-------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| cloud_functions   | Cloud functions which implement the legacy Trase API        | [cloud_functions/README.md](cloud_functions/README.md)                                                   |
| infrastructure    | Terraform project & GH Actions workflow                     | [infrastructure/README.md](infrastructure/README.md)                                                     |

### Deployment and Infrastructure

The project is deployed on the Google Cloud Platform (GCP) using GitHub Actions for continuous integration and deployment. The infrastructure is provisioned and managed using Terraform scripts, ensuring consistent and reproducible deployments.

