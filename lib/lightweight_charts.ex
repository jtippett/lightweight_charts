defmodule LightweightCharts do
  @moduledoc """
  TradingView Lightweight Charts for Phoenix LiveView.

  Provides declarative chart configuration via Elixir structs and a
  bundled JavaScript hook for rendering interactive financial charts.

  ## Quick Start

      chart =
        LightweightCharts.Chart.new()
        |> LightweightCharts.Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> LightweightCharts.Chart.add_series(
          LightweightCharts.Series.candlestick(id: "candles", up_color: "#26a69a")
        )

  See `LightweightCharts.Chart` for the full builder API and
  `LightweightCharts.Live.ChartComponent` for LiveView integration.
  """
end
