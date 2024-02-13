The library takes authentication information from env vars in development / cloud function secrets in GCP.
These ones are required:
- BIGQUERY_PROJECT - the GCP project id
- BIGQUERY_CREDENTIALS - the JSON credentials
- BIGQUERY_SNAPSHOT - the symbol of the snapshot, e.g. "_2024-01-17_oxindole"

To run a function locally:

`pip install -r requirements.txt`
`PATH=$PATH:~/.local/bin`

`functions-framework-python --target index`
