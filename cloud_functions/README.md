Big Query authentication using json credentials
https://cloud.google.com/ruby/docs/reference/google-cloud-bigquery/latest/AUTHENTICATION

The library takes authentication information from env vars in development / cloud function secrets in GCP.
These ones are required:
- BIGQUERY_PROJECT - the GCP project id
- BIGQUERY_CREDENTIALS - the JSON credentials

Please note: the credentials come as a multiline string, 2 things to mind:
- dotenv requires multiline strings to be wrapped in double quotes, therefore all double quotes from the json need to be quoted with `\`
- the private key comes as a single line string with `\n` characters in it, for this to be processed correctly dotenv version 3 is needed (currently in beta)