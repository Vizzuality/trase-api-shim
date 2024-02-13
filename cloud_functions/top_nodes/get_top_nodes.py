from google.cloud import bigquery

class GetTopNodes:
    DEFAULT_TOP_N = 15

    def __init__(self, bigquery_client, bigquery_snapshot, parameters):
        self.bigquery_client = bigquery_client
        self.bigquery_snapshot = bigquery_snapshot
        self.parameters = parameters
        self.result = None

    def call(self):
        self.sanitise_parameters()

        # construct the context_slug from the country_id and commodity_id
        self.context_slug = f"{self.country_id}-{self.commodity_id}"

        available_node_column_names = self.available_node_column_names()
        if self.node_type_id not in available_node_column_names:              
            raise ValueError("node_type_id not recognised")
        available_metric_column_names = self.available_metric_column_names()
        if self.cont_attribute_id not in available_metric_column_names:           
            raise ValueError("cont_attribute_id not recognised")

        node_filters = {}
        for column_name in ["source", "exporter", "importer", "destination"]:
            key = column_name + "s_ids"
            value = self.parameters.get(key)
            if not value:
                continue

            exact_column_name = self.parameters.get(column_name + "_node_type_id")
            if exact_column_name in available_node_column_names:
                # strip and upcase value to match the format in the supply_chains table
                node_filters[exact_column_name] = value.upper().strip()
                    
        flows = self.flows(
            self.context_slug,
            self.cont_attribute_id,
            self.node_type_id,
            self.start_year,
            self.end_year,
            node_filters,
            self.parameters.get("top_n") or self.DEFAULT_TOP_N
        )
        self.result = self.build_response(flows)

    def sanitise_parameters(self):
        self.country_id= self.parameters.get("country_id")
        if self.country_id is None:
            raise TypeError("country_id required")
        self.commodity_id = self.parameters.get("commodity_id")
        if self.commodity_id is None:
            raise TypeError("commodity_id required")
        self.cont_attribute_id = self.parameters.get("cont_attribute_id")
        if self.cont_attribute_id is None:
            raise TypeError("cont_attribute_id required")
        self.node_type_id = self.parameters.get("node_type_id")
        if self.node_type_id is None:
            raise TypeError("node_type_id required")
        self.start_year = self.parameters.get("start_year")
        if self.start_year is None:
            raise TypeError("start_year required")
        self.end_year = self.parameters.get("end_year")
        if self.end_year is None:
            self.end_year = self.start_year

    def available_node_column_names(self):
        sql = f"""
            SELECT
            column_in_supply_chains_table
            FROM `trase-396112.website.flows_nodes_metadata{self.bigquery_snapshot}`
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

    def available_metric_column_names(self):
        sql = f"""
            SELECT
            column_in_supply_chains_table
            FROM `trase-396112.website.flows_metrics_metadata{self.bigquery_snapshot}`
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

    def flows(self, context_slug, metric_column, node_column, start_year, end_year, node_filters, top_n):
        conditions = ["context_slug = @context_slug", "year >= @start_year", "year <= @end_year"]
        query_parameters=[
            bigquery.ScalarQueryParameter("context_slug", "STRING", context_slug),
            bigquery.ScalarQueryParameter("start_year", "INT64", start_year),
            bigquery.ScalarQueryParameter("end_year", "INT64", end_year),
            bigquery.ScalarQueryParameter("top_n", "INT64", top_n)
        ]
        # add conditions and query parameters for each filter if value present
        for column_name, column_value in node_filters.items():
            if column_value:
                conditions.append(f"{column_name} = @{column_name}_node")
                query_parameters.append(bigquery.ScalarQueryParameter(f"{column_name}_node", "STRING", column_value))

        # constructs the query to get the top-n flows by sum of metric column aggregated by node column in the given context
        # optionally filtered by nodes
        sql = f"SELECT {node_column} AS node, SUM({metric_column}) AS value FROM `trase-396112.website.supply_chains{self.bigquery_snapshot}`"
        sql += " WHERE " + " AND ".join(conditions)
        sql += f" GROUP BY node ORDER BY value DESC LIMIT @top_n"
        
        job_config = bigquery.QueryJobConfig(query_parameters=query_parameters)
        return self.bigquery_client.query(sql, job_config=job_config).result()

    def build_response(self, flows):
        data = [
            {
                'y': row['node'],
                'x0': row['value']
            }
            for row in flows
        ]
        return {'data': data}
