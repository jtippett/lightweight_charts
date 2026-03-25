defmodule LightweightCharts.SeriesTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Series
  alias LightweightCharts.Encoder

  describe "constructor functions" do
    test "candlestick/1 creates a candlestick series" do
      s = Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      assert s.type == :candlestick
      assert s.id == "candles"
      assert s.up_color == "#26a69a"
    end

    test "line/1 creates a line series" do
      s = Series.line(id: "sma", color: "#2196f3", line_width: 2)
      assert s.type == :line
      assert s.color == "#2196f3"
      assert s.line_width == 2
    end

    test "area/1 creates an area series" do
      s = Series.area(id: "vol", top_color: "rgba(46,220,135,0.4)", line_color: "#33D778")
      assert s.type == :area
      assert s.top_color == "rgba(46,220,135,0.4)"
    end

    test "bar/1 creates a bar series" do
      s = Series.bar(id: "ohlc", up_color: "#26a69a")
      assert s.type == :bar
    end

    test "histogram/1 creates a histogram series" do
      s = Series.histogram(id: "vol", color: "#26a69a", base: 0)
      assert s.type == :histogram
      assert s.base == 0
    end

    test "baseline/1 creates a baseline series" do
      s = Series.baseline(id: "pnl", base_value: 100.0, top_line_color: "#26a69a")
      assert s.type == :baseline
      assert s.base_value == 100.0
    end
  end

  describe "encoding" do
    test "encodes candlestick series to JS-compatible map" do
      s = Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      encoded = Encoder.encode(s)

      assert encoded["type"] == "Candlestick"
      assert encoded["id"] == "candles"
      assert encoded["options"]["upColor"] == "#26a69a"
      assert encoded["options"]["downColor"] == "#ef5350"
    end

    test "encodes line series with line style enum" do
      s = Series.line(id: "sma", color: "#2196f3", line_style: :dashed, line_type: :curved)
      encoded = Encoder.encode(s)

      assert encoded["type"] == "Line"
      assert encoded["options"]["color"] == "#2196f3"
      assert encoded["options"]["lineStyle"] == 2
      assert encoded["options"]["lineType"] == 2
    end

    test "encodes common series options" do
      s =
        Series.line(
          id: "sma",
          title: "SMA 20",
          visible: true,
          price_line_visible: false,
          price_scale_id: "right"
        )

      encoded = Encoder.encode(s)

      assert encoded["options"]["title"] == "SMA 20"
      assert encoded["options"]["visible"] == true
      assert encoded["options"]["priceLineVisible"] == false
      assert encoded["options"]["priceScaleId"] == "right"
    end

    test "encodes series with pane_index" do
      s = Series.histogram(id: "vol", color: "#26a69a", pane_index: 1)
      encoded = Encoder.encode(s)

      assert encoded["paneIndex"] == 1
    end
  end
end
