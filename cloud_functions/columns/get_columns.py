from google.cloud import bigquery

class GetColumns:
    def __init__(self, bigquery_client, bigquery_snapshot, parameters):
        self.bigquery_client = bigquery_client
        self.bigquery_snapshot = bigquery_snapshot
        self.parameters = parameters
        self.result = None

    def call(self):
        self.sanitise_parameters()
        columns = self.flow_nodes_metadata(self.context_slug)
        self.result = self.build_response(columns)

    def sanitise_parameters(self):
        self.context_slug = self.parameters.get('context_id')
        if self.context_slug is None:
            raise TypeError("context_id required")

    def flow_nodes_metadata(self, context_slug):
        sql = f"""
            SELECT
            column_in_supply_chains_table,
            short_name,
            display_order,
            display_by_default
            FROM `trase-396112.website.flows_nodes_metadata{self.bigquery_snapshot}`
            WHERE context_slug = @context_slug
            ORDER BY display_order
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("context_slug", "STRING", context_slug)
            ]
        )
        return self.bigquery_client.query(sql, job_config=job_config).result()

    def build_response(self, columns):
        data = [
            {
                'id': row['column_in_supply_chains_table'],
                'name': row['short_name'],
                'position': row['display_order'],
                'isDefault': row['display_by_default']
            }
            for row in columns
        ]
        return {'data': data}
