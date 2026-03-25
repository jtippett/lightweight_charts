defmodule LightweightCharts do
  @moduledoc """
  TradingView Lightweight Charts for Phoenix LiveView.

  Provides declarative chart configuration via Elixir structs and a
  bundled JavaScript hook for rendering interactive financial charts.

  ## Quick Start

  ### 1. Build your chart configuration

      alias LightweightCharts.{Chart, Series}

      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> Chart.crosshair(mode: :magnet)
        |> Chart.time_scale(time_visible: true)
        |> Chart.add_series(
          Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
        )
        |> Chart.on(:click)

  ### 2. Render in your LiveView template

      <LightweightCharts.chart id="price-chart" chart={@chart} class="h-96 w-full" />

  ### 3. Push data from your LiveView

      LightweightCharts.push_data(socket, "price-chart", "candles", candle_data)
      LightweightCharts.push_update(socket, "price-chart", "candles", new_candle)

  ### 4. Handle interaction events

      def handle_event("lc:click", %{"time" => time}, socket) do
        # User clicked a point on the chart
        {:noreply, socket}
      end

  ## JavaScript Setup

  In your `app.js`:

      import { LightweightChartsHook } from "lightweight_charts"

      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { LightweightCharts: LightweightChartsHook }
      })
  """

  use Phoenix.Component

  alias LightweightCharts.{Chart, Live.Helpers}

  # Re-export the function component
  attr(:id, :string, required: true)
  attr(:chart, Chart, required: true)
  attr(:class, :string, default: nil)
  attr(:style, :string, default: nil)
  attr(:rest, :global)

  @doc "Renders a lightweight chart. See `LightweightCharts.Live.ChartComponent.chart/1`."
  def chart(assigns), do: LightweightCharts.Live.ChartComponent.chart(assigns)

  # Re-export helpers
  defdelegate push_data(socket, chart_id, series_id, data), to: Helpers
  defdelegate push_update(socket, chart_id, series_id, point), to: Helpers
  defdelegate push_options(socket, chart_id, target, options), to: Helpers
  defdelegate fit_content(socket, chart_id), to: Helpers
  defdelegate set_visible_range(socket, chart_id, from, to), to: Helpers
  defdelegate set_markers(socket, chart_id, series_id, markers), to: Helpers
end
