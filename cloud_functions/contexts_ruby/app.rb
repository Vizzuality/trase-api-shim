require "functions_framework"

require "./get_contexts.rb"

FunctionsFramework.on_startup do
  # in development load env vars from .env
  # in production, env vars are set in the cloud function environment
  require "dotenv"
  Dotenv.load

  bigquery = Google::Cloud::Bigquery.new

  # To pass data into function invocations, the best practice is to set a
  # key-value pair using the Ruby Function Framework's built-in "set_global"
  # method. Functions can call the "global" method to retrieve the data by key.
  # (You can also use Ruby global variables or "toplevel" local variables, but
  # they can make it difficult to isolate global data for testing.)
  set_global :bigquery, bigquery
end

# Register an HTTP function with the Functions Framework
FunctionsFramework.http "index" do |request|
  # Retrieve the bigquery client initialised by the on_startup block.
  bigquery = global :bigquery

  service = GetContexts.new(bigquery)
  if service.call
    service.result.to_json
  else
    service.error
  end
end
