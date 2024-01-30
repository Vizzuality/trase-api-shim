require "google/cloud/bigquery"

class GetContexts
  attr_reader :result, :errors

  def initialize(bigquery)
    @bigquery = bigquery
  end

  def call
    begin
      metrics = flow_metrics_metadata
      contexts = supply_chain_contexts
      @result = build_response(metrics, contexts)
    rescue Google::Cloud::Error => e
      @error = e
    end
  end

  private

  # fetch metrics
  def flow_metrics_metadata
    sql = <<-SQL
      SELECT
      context_slug
      , column_in_supply_chains_table
      , unit
      , unit_abbreviation
      , years_available
      , max_year
      , short_name
      , long_name
      FROM `trase-396112.website.flows_metrics_metadata_2024-01-17_oxindole`
      ORDER BY context_slug, column_in_supply_chains_table
    SQL

    @bigquery.query sql
  end

  # fetch contexts
  def supply_chain_contexts
    sql = <<-SQL
      SELECT
      c.context_slug
      , c.country_of_production
      , c.country_of_production_slug
      , c.commodity
      , c.commodity_slug
      FROM `trase-396112.website.supply_chains_contexts_2024-01-17_oxindole` c
      WHERE country_of_production NOT IN (
          'AUSTRALIA', 'MALAYSIA', 'SOUTH AFRICA', 'THAILAND', 'VIETNAM'
        )
      GROUP BY 1,2,3,4,5
      ORDER BY c.context_slug
    SQL

    @bigquery.query sql
  end

  def build_response(metrics, contexts)
    metrics_by_context = metrics.group_by { |m| m[:context_slug] }

    data = contexts.map do |row|
      attributes = metrics_by_context[row[:context_slug]]
      {
        id: row[:context_slug],
        countryId: row[:country_of_production_slug],
        countryName: row[:country_of_production],
        commodityId: row[:commodity_slug],
        commodityName: row[:commodity],
        worldMap: {
          geoId: nil # TODO
        },
        resizeBy: attributes.map do |attribute|
          {
            unit: attribute[:unit_abbreviation],
            years: attribute[:years_available],
            attributeId: attribute[:column_in_supply_chains_table],
            label: attribute[:short_name]
          }
        end
      }
    end
    {data: data}
  end
end
