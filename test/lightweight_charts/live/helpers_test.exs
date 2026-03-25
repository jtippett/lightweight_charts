defmodule LightweightCharts.Live.HelpersTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Live.Helpers

  describe "event name generation" do
    test "push_data builds correct event name" do
      assert Helpers.event_name("my-chart", :set_data) == "lc:my-chart:set_data"
    end

    test "push_update builds correct event name" do
      assert Helpers.event_name("my-chart", :update) == "lc:my-chart:update"
    end

    test "apply_options builds correct event name" do
      assert Helpers.event_name("my-chart", :apply_options) == "lc:my-chart:apply_options"
    end

    test "fit_content builds correct event name" do
      assert Helpers.event_name("my-chart", :fit_content) == "lc:my-chart:fit_content"
    end

    test "set_visible_range builds correct event name" do
      assert Helpers.event_name("my-chart", :set_visible_range) == "lc:my-chart:set_visible_range"
    end

    test "set_markers builds correct event name" do
      assert Helpers.event_name("my-chart", :set_markers) == "lc:my-chart:set_markers"
    end
  end

  describe "encode_data_points/1" do
    test "converts DateTime times in data points" do
      data = [
        %{time: ~U[2024-01-15 00:00:00Z], value: 42.5},
        %{time: ~U[2024-01-16 00:00:00Z], value: 43.1}
      ]

      encoded = Helpers.encode_data_points(data)

      assert hd(encoded)["time"] == 1705276800
      assert hd(encoded)["value"] == 42.5
    end

    test "converts Date times to strings" do
      data = [%{time: ~D[2024-01-15], open: 100, high: 105, low: 99, close: 103}]
      encoded = Helpers.encode_data_points(data)

      assert hd(encoded)["time"] == "2024-01-15"
      assert hd(encoded)["open"] == 100
    end

    test "passes through integer timestamps" do
      data = [%{time: 1705276800, value: 42.5}]
      encoded = Helpers.encode_data_points(data)

      assert hd(encoded)["time"] == 1705276800
    end
  end
end
