class GetContexts:
    def __init__(self, bigquery_client, bigquery_snapshot, cc):
        self.bigquery_client = bigquery_client
        self.bigquery_snapshot = bigquery_snapshot
        self.cc = cc
        self.result = None

    def call(self):
        metrics = self.flow_metrics_metadata()
        contexts = self.supply_chain_contexts()
        self.result = self.build_response(metrics, contexts)

    def flow_metrics_metadata(self):
        sql = f"""
            SELECT
            context_slug,
            column_in_supply_chains_table,
            unit,
            unit_abbreviation,
            years_available,
            max_year,
            short_name,
            long_name
            FROM `{self.bigquery_client.project}.website.flows_metrics_metadata{self.bigquery_snapshot}`
            ORDER BY context_slug, column_in_supply_chains_table
        """
        return self.bigquery_client.query(sql).result()

    def supply_chain_contexts(self):
        sql = f"""
            SELECT
            c.context_slug,
            c.country_of_production,
            c.country_of_production_slug,
            c.commodity,
            c.commodity_slug
            FROM `{self.bigquery_client.project}.website.supply_chains_contexts{self.bigquery_snapshot}` c
            WHERE country_of_production NOT IN (
                'AUSTRALIA', 'MALAYSIA', 'SOUTH AFRICA', 'THAILAND', 'VIETNAM'
            )
            GROUP BY 1,2,3,4,5
            ORDER BY c.context_slug
        """
        return self.bigquery_client.query(sql).result()

    def build_response(self, metrics, contexts):            
        metrics_by_context = {}
        for metric in metrics:
            metrics_by_context.setdefault(metric['context_slug'], []).append(metric)

        data = []
        for row in contexts:
            attributes = metrics_by_context.get(row['context_slug'], [])
            data.append({
                'id': row['context_slug'],
                'countryId': row['country_of_production_slug'],
                'countryName': row['country_of_production'],
                'commodityId': row['commodity_slug'],
                'commodityName': row['commodity'],
                'worldMap': {
                    'geoId': self.cc.convert(names=row['country_of_production'], to='iso2'),
                },
                'resizeBy': [{
                    'unit': attribute['unit_abbreviation'],
                    'years': attribute['years_available'],
                    'attributeId': attribute['column_in_supply_chains_table'],
                    'name': attribute['short_name'],
                    'label': attribute['long_name'],
                } for attribute in attributes]
            })

        return {'data': data}
