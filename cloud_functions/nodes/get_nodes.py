from google.cloud import bigquery

class GetNodes:
    def __init__(self, bigquery_client, bigquery_snapshot, cc, parameters):
        self.bigquery_client = bigquery_client
        self.bigquery_snapshot = bigquery_snapshot
        self.cc = cc
        self.parameters = parameters
        self.result = None

    def call(self):
        self.sanitise_parameters()
        nodes = self.nodes()
        self.result = self.build_response(nodes)

    def sanitise_parameters(self):
        self.context_slug = self.parameters.get('context_id')
        if self.context_slug is None:
            raise TypeError("context_id required")
    
        node_types_ids_cs_str = self.parameters.get('node_types_ids')
        # this should be a comma-separated list of node_types_ids
        node_types_ids = node_types_ids_cs_str.split(",") if node_types_ids_cs_str else []
        if len(node_types_ids) == 0:
            raise TypeError("node_types_ids required")

        # sanitize column names
        self.column_names = self.sanitize_column_names(node_types_ids)
        if len(self.column_names) == 0:        
            raise ValueError("No valid columns given")

    def is_geo_column(self, column_name):
        return "country" in column_name.lower()

    def sanitize_column_names(self, column_names):
        available_node_column_names = self.available_node_column_names()
        return [node_column_id for node_column_id in column_names if node_column_id in available_node_column_names]

    def available_node_column_names(self):
        sql = f"""
            SELECT
            column_in_supply_chains_table
            FROM `{self.bigquery_client.project}.website.flows_nodes_metadata{self.bigquery_snapshot}`
            WHERE context_slug = @context_slug
            ORDER BY display_order
        """
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("context_slug", "STRING", self.context_slug)
            ]
        )
        result = self.bigquery_client.query(sql, job_config=job_config).result()
        return [row['column_in_supply_chains_table'] for row in result]

    def nodes(self):
        # construct a UNION ALL query
        union_partial_queries = []
        for column_name in self.column_names:
            # for each column in column_names, select the distinct values of that column as name and the name of the column as type
            select_columns = [
                f"{column_name} AS name",
                f"'{column_name}' AS type"
            ]
            union_partial_queries.append(
                f"""
                SELECT
                DISTINCT {", ".join(select_columns)}
                FROM `{self.bigquery_client.project}.website.supply_chains{self.bigquery_snapshot}`
                WHERE context_slug = @context_slug
                AND {column_name} IS NOT NULL
                """
            )
        sql = " UNION ALL ".join(union_partial_queries)
        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("context_slug", "STRING", self.context_slug)
            ]
        )
        return self.bigquery_client.query(sql, job_config=job_config).result()

    def build_response(self, nodes):
        data = [
            # if it is a geo column, convert the name to a geoId
            {
                'id': row['name'].replace(" ", "-").lower(),
                'name': row['name'],
                'type': row['type'],
                'geoId': self.cc.convert(row['name'], to='ISO2', not_found=None) if self.is_geo_column(row['type']) else None
            }
            for row in nodes
        ]
        return {'data': data}
