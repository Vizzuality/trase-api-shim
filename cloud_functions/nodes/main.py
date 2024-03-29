import functions_framework

import json

from google.oauth2 import service_account
from google.cloud import bigquery
from google.cloud import error_reporting
import country_converter as coco

import os
from dotenv import load_dotenv

# Initialize BigQuery client
load_dotenv()
service_account_info = json.loads(os.getenv("BIGQUERY_CREDENTIALS"))
credentials = service_account.Credentials.from_service_account_info(service_account_info)
bigquery_client = bigquery.Client(project=os.getenv("BIGQUERY_PROJECT"), credentials=credentials)
error_reporting_client = error_reporting.Client()

# Set global variable to pass data into function invocations
globals()["bigquery"] = bigquery_client
globals()["error_reporting"] = error_reporting_client
globals()["cc"] = coco.CountryConverter()

from get_nodes import GetNodes

@functions_framework.http
def index(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    """

    # For more information about CORS and CORS preflight requests, see:
    # https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request

    # Set CORS headers for the preflight request
    if request.method == "OPTIONS":
        # Allows GET requests from any origin with the Content-Type
        # header and caches preflight response for an 3600s
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }

        return ("", 204, headers)

    # Set CORS headers for the main request
    headers = {"Access-Control-Allow-Origin": "*"}

    parameters = {
        "context_id": request.args.get("context_id"),
        "node_types_ids": request.args.get("node_types_ids")
    }

    try:
        service = GetNodes(globals()["bigquery"], os.getenv("BIGQUERY_SNAPSHOT"), globals()["cc"], parameters)
        service.call()
        return (service.result, 200, headers)
    except TypeError as e:
        return ({"error": str(e)}, 400, headers)
    except ValueError as e:
        return ({"error": str(e)}, 400, headers)
    except Exception as e:
        globals()["error_reporting"].report_exception()
        return ({"error": str(e)}, 500, headers)
