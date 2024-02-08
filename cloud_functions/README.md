The library takes authentication information from env vars in development / cloud function secrets in GCP.
These ones are required:
- BIGQUERY_PROJECT - the GCP project id
- BIGQUERY_CREDENTIALS - the JSON credentials

To run a function locally:

`pip install -r requirements.txt`
`PATH=$PATH:~/.local/bin`

`functions-framework-python --target index`
