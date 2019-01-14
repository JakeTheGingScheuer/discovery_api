alias StreamingMetrics.Hostname
require Logger

defmodule DiscoveryApiWeb.MetricsCollectorService do
  @metric_collector Application.get_env(:discovery_api, :collector)
  def record_csv_download_count_metrics(dataset_id, table_name) do
    record_metrics("downloaded_csvs", [
      {"DatasetId", "#{dataset_id}"},
      {"Table", "#{table_name}"}
    ])
  end

  def record_query_metrics(dataset_id, table_name, return_type) do
    record_metrics("data_queries", [
      {"DatasetId", "#{dataset_id}"},
      {"Table", "#{table_name}"},
      {"ContentType", "#{return_type}"}
    ])
  end

  defp record_metrics(metric_name, labels) do
    hostname = Hostname.get()

    @metric_collector.count_metric(1, metric_name, [{"PodHostname", "#{hostname}"}] ++ labels)
    |> List.wrap()
    |> @metric_collector.record_metrics("discovery_api")
    |> case do
      {:ok, _} -> {}
      {:error, reason} -> Logger.warn("Unable to write application metrics: #{inspect(reason)}")
    end
  end
end
