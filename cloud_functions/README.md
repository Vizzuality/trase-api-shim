# Cloud functions
Cloud functions which implement the legacy Trase API using BigQuery.

## Source code organisation

Each of the functions' code is contained in a subdirectory with the following files:
- `main.py` - function entry point, wrapper code for GCP endpoint and initialisation of BigQuery client
- `[service].py` - actual logic of the function
- `requirements.txt` - dependencies of the function
- `.env.sample` - sample .env file for local development 

## Runtime environment variables

Each function requires the following variables / secrets:
- `BIGQUERY_PROJECT` - the GCP project id
- `BIGQUERY_CREDENTIALS` - the JSON credentials
- `BIGQUERY_SNAPSHOT` - the symbol of the snapshot, e.g. "_2024-03-05_burk"

Those need to be set:
- when running locally, in each cloud function's .env file.
- when running in GCP, in each cloud function's environment. That is done automatically by Terraform - please refer to [infrastructure documentation](../infrastructure/README.md).

## Running locally

Inside the function directory run:

`pip install -r requirements.txt`
`PATH=$PATH:~/.local/bin`

`functions-framework-python --target index`

The function starts on port 8080 by default:

`curl "http://localhost:8080/index"`

## Deployment

Code changes are deployed automatically by a GH Actions workflow when pushed to the `main` branch. Please refer to [infrastructure documentation](../infrastructure/README.md) for details.

## How to update the BQ snapshot

In order to make the function pull data from a new snapshot, it is easiest to use terraform to update the env var with the snapshot symbol for all functions.
