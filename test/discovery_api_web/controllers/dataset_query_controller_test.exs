defmodule DiscoveryApiWeb.DatasetQueryControllerTest do
  use ExUnit.Case
  use DiscoveryApiWeb.ConnCase
  use Placebo
  alias DiscoveryApi.Data.Thrive
  alias StreamingMetrics.PrometheusMetricCollector, as: MetricCollector

  describe "fetch dataset csv" do
    setup do
      mock_hive_schema_result = %{
        "fields" => [
          %{
            "name" => "name"
          },
          %{
            "name" => "animal"
          },
          %{
            "name" => "age"
          }
        ]
      }

      allow(HTTPoison.get(ends_with("feed/1"), any()),
        return: HttpHelper.create_response(body: generate_metadata_result())
      )

      allow(HTTPoison.get(ends_with("schemas/test/tables/bigdata"), any()),
        return: HttpHelper.create_response(body: mock_hive_schema_result)
      )

      allow(
        Thrive.stream_results(
          any(),
          any()
        ),
        return: {:ok, Stream.take(get_common_expected_data(), 3)}
      )

      :ok
    end

    test "maps the data to the correct csv structure", %{conn: conn} do
      actual = get(conn, "/v1/api/dataset/1/csv") |> response(200)
      assert(generate_expected_csv() == actual)
    end

    test "maps the data to the correct json structure", %{conn: conn} do
      actual = get(conn, "/v1/api/dataset/1/query?type=json") |> response(200)
      assert(generate_expected_json() == actual)
    end

    test "thrive stream results called with correct query", %{conn: conn} do
      uri_string = URI.encode("/v1/api/dataset/1/query?query=WHERE name=Austin6")

      expected = "select * from test.bigdata WHERE name=Austin6"
      # This is hardcoded in the function
      chunk_size = 1000

      actual = get(conn, uri_string) |> response(200)
      assert_called Thrive.stream_results(expected, chunk_size)
    end

    test "thrive stream results called with correct query (POST version)", %{conn: conn} do
      uri_string = "/v1/api/dataset/1/query"

      body = """
      {
        "query": "WHERE name=Austin6"
      }
      """

      expected = "select * from test.bigdata WHERE name=Austin6"
      # This is hardcoded in the function
      chunk_size = 1000

      conn = conn |> put_req_header("content-type", "application/json")

      actual = post(conn, uri_string, body) |> response(200)
      assert_called Thrive.stream_results(expected, chunk_size)
    end

    test "params are parsed correctly" do
      uri_string = "/v1/api/dataset/1/query"

      query_tests = [
        # {json, expected string}
        {
          ~s({ "query": "WHERE name=Austin6" }),
          "select * from test.bigdata WHERE name=Austin6"
        },
        {
          ~s({ "columns": ["a", "b", "c"] }),
          "select a,b,c from test.bigdata "
        },
        {
          ~s({ "query": "WHERE name=Austin6", "columns": ["a", "b", "c"] }),
          "select a,b,c from test.bigdata WHERE name=Austin6"
        },
        {
          ~s({}),
          "select * from test.bigdata "
        }
      ]

      conn = conn |> put_req_header("content-type", "application/json")

      Enum.each(query_tests, fn {body, expected} ->
        actual = post(conn, uri_string, body) |> response(200)
        assert_called Thrive.stream_results(expected, 1000)
      end)
    end

    test "metrics are sent for a count of the uncached entities" do
      expect(
        MetricCollector.record_metrics(
          [
            %{
              name: "downloaded_csvs",
              value: 1,
              dimensions: [{"PodHostname", any()}, {"DatasetId", "1"}, {"Table", "bigdata"}]
            }
          ],
          "discovery_api"
        ),
        return: {:ok, %{}},
        meck_options: [:passthrough]
      )

      get(conn, "/v1/api/dataset/1/csv")
    end
  end

  describe "error paths" do
    test "kylo feed down returns 500" do
      allow(HTTPoison.get(ends_with("feed/1"), any()),
        return: HttpHelper.create_response(error_reason: "There was an error")
      )

      assert get(conn, "/v1/api/dataset/1/csv")
             |> response(500)
    end

    test "kylo hive metadata down returns 500" do
      allow(HTTPoison.get(ends_with("feed/1"), any()),
        return: HttpHelper.create_response(body: generate_metadata_result)
      )

      allow(HTTPoison.get(ends_with("schemas/test/tables/bigdata"), any()),
        return: HttpHelper.create_response(error_reason: "There was an error")
      )

      assert get(conn, "/v1/api/dataset/1/csv")
             |> response(500)
    end

    test "thrive streaming down returns 500" do
      mock_hive_schema_result = %{
        "fields" => [
          %{
            "name" => "name"
          }
        ]
      }

      allow(
        HTTPoison.get(ends_with("feed/1"), any()),
        return: HttpHelper.create_response(body: generate_metadata_result)
      )

      allow(
        HTTPoison.get(ends_with("schemas/test/tables/bigdata"), any()),
        return: HttpHelper.create_response(body: mock_hive_schema_result)
      )

      allow(
        Thrive.stream_results(any(), any()),
        return: {:error, "everything is awesome"}
      )

      assert get(conn, "/v1/api/dataset/1/csv")
             |> response(500)
    end

    test "error reason parser doesn't let you talk about Hive" do
      reason_from_hive = "Hive exists!"
      assert(DiscoveryApiWeb.DatasetQueryController.parse_error_reason(reason_from_hive) != reason_from_hive)
    end
  end

  defp get_common_expected_data() do
    [
      {"Austin5", "The Worst5", 25},
      {"Austin6", "The Worst6", 26}
    ]
  end

  defp generate_metadata_result() do
    %{
      "systemName" => "bigdata",
      "category" => %{
        "systemName" => "test"
      }
    }
  end

  defp generate_expected_csv() do
    """
    name,animal,age
    Austin5,The Worst5,25
    Austin6,The Worst6,26
    """
  end

  defp generate_expected_json() do
    "{\"content\":{\"id\":\"1\",\"data\":[{\"name\":\"Austin5\",\"animal\":\"The Worst5\",\"age\":25},{\"name\":\"Austin6\",\"animal\":\"The Worst6\",\"age\":26}],\"columns\":[\"name\",\"animal\",\"age\"]}}"
  end
end