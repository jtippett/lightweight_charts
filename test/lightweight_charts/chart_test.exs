defmodule LightweightCharts.ChartTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Chart
  alias LightweightCharts.Series

  describe "new/0" do
    test "creates empty chart" do
      chart = Chart.new()
      assert chart.series == []
      assert chart.events == []
      assert chart.layout == nil
    end
  end

  describe "builder functions" do
    test "layout/2 sets layout options" do
      chart = Chart.new() |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      assert chart.layout.background_color == "#1a1a2e"
      assert chart.layout.text_color == "#e0e0e0"
    end

    test "grid/2 sets grid options" do
      chart = Chart.new() |> Chart.grid(vert_lines_visible: false)
      assert chart.grid.vert_lines_visible == false
    end

    test "crosshair/2 sets crosshair options" do
      chart = Chart.new() |> Chart.crosshair(mode: :magnet)
      assert chart.crosshair.mode == :magnet
    end

    test "time_scale/2 sets time scale options" do
      chart = Chart.new() |> Chart.time_scale(time_visible: true, bar_spacing: 10)
      assert chart.time_scale.time_visible == true
    end

    test "right_price_scale/2 sets right price scale" do
      chart = Chart.new() |> Chart.right_price_scale(visible: true, mode: :logarithmic)
      assert chart.right_price_scale.visible == true
      assert chart.right_price_scale.mode == :logarithmic
    end

    test "left_price_scale/2 sets left price scale" do
      chart = Chart.new() |> Chart.left_price_scale(visible: true)
      assert chart.left_price_scale.visible == true
    end

    test "add_series/2 appends a series" do
      chart =
        Chart.new()
        |> Chart.add_series(Series.candlestick(id: "candles"))
        |> Chart.add_series(Series.line(id: "sma"))

      assert length(chart.series) == 2
      assert Enum.at(chart.series, 0).id == "candles"
      assert Enum.at(chart.series, 1).id == "sma"
    end

    test "on/2 subscribes to events" do
      chart = Chart.new() |> Chart.on(:click) |> Chart.on(:crosshair_move)
      assert :click in chart.events
      assert :crosshair_move in chart.events
    end
  end

  describe "pipeline composition" do
    test "full pipeline builds a complete chart config" do
      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> Chart.grid(vert_lines_visible: false)
        |> Chart.crosshair(mode: :magnet)
        |> Chart.time_scale(time_visible: true)
        |> Chart.add_series(
          Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
        )
        |> Chart.add_series(Series.line(id: "sma", color: "#2196f3", line_width: 2))
        |> Chart.on(:click)

      assert chart.layout.background_color == "#1a1a2e"
      assert chart.crosshair.mode == :magnet
      assert length(chart.series) == 2
      assert :click in chart.events
    end
  end

  describe "to_json/1" do
    test "encodes full chart to JSON-compatible map" do
      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e")
        |> Chart.crosshair(mode: :magnet)
        |> Chart.add_series(Series.candlestick(id: "candles", up_color: "#26a69a"))
        |> Chart.on(:click)

      json = Chart.to_json(chart)

      assert json["layout"]["background"]["color"] == "#1a1a2e"
      assert json["crosshair"]["mode"] == 1
      assert length(json["series"]) == 1
      assert hd(json["series"])["type"] == "Candlestick"
      assert "click" in json["events"]
    end

    test "omits nil top-level options" do
      chart = Chart.new() |> Chart.add_series(Series.line(id: "test"))
      json = Chart.to_json(chart)

      refute Map.has_key?(json, "layout")
      refute Map.has_key?(json, "grid")
      assert Map.has_key?(json, "series")
    end
  end
end
