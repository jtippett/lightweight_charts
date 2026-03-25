defmodule LightweightCharts.Live.Helpers do
  @moduledoc """
  Helper functions for pushing chart data and commands from LiveView to the JS hook.

  ## Usage in a LiveView

      def mount(_params, _session, socket) do
        chart = Chart.new() |> Chart.add_series(Series.candlestick(id: "candles"))
        {:ok, assign(socket, chart: chart)}
      end

      def handle_info({:new_candles, data}, socket) do
        {:noreply, push_data(socket, "price-chart", "candles", data)}
      end

      def handle_info({:new_candle, candle}, socket) do
        {:noreply, push_update(socket, "price-chart", "candles", candle)}
      end
  """

  import Phoenix.LiveView, only: [push_event: 3]
  alias LightweightCharts.Encoder

  @doc """
  Pushes a full dataset to a series, replacing existing data.

  Triggers `series.setData(data)` on the JS side.
  """
  @spec push_data(Phoenix.LiveView.Socket.t(), String.t(), String.t(), list(map())) ::
          Phoenix.LiveView.Socket.t()
  def push_data(socket, chart_id, series_id, data) do
    push_event(socket, event_name(chart_id, :set_data), %{
      series_id: series_id,
      data: encode_data_points(data)
    })
  end

  @doc """
  Pushes a single data point update to a series.

  Triggers `series.update(point)` on the JS side. If the point's time
  matches the last bar, it updates that bar. Otherwise appends a new bar.
  """
  @spec push_update(Phoenix.LiveView.Socket.t(), String.t(), String.t(), map()) ::
          Phoenix.LiveView.Socket.t()
  def push_update(socket, chart_id, series_id, point) do
    push_event(socket, event_name(chart_id, :update), %{
      series_id: series_id,
      point: encode_data_point(point)
    })
  end

  @doc """
  Pushes option changes to the chart or a specific series.

  Pass `target: "chart"` to update chart options, or `target: series_id`
  to update a specific series.
  """
  @spec push_options(Phoenix.LiveView.Socket.t(), String.t(), String.t(), map() | keyword()) ::
          Phoenix.LiveView.Socket.t()
  def push_options(socket, chart_id, target, options) do
    push_event(socket, event_name(chart_id, :apply_options), %{
      target: target,
      options: Encoder.encode(Map.new(options))
    })
  end

  @doc "Triggers `timeScale().fitContent()` — auto-fits all data in view."
  @spec fit_content(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  def fit_content(socket, chart_id) do
    push_event(socket, event_name(chart_id, :fit_content), %{})
  end

  @doc "Sets the visible time range."
  @spec set_visible_range(Phoenix.LiveView.Socket.t(), String.t(), term(), term()) ::
          Phoenix.LiveView.Socket.t()
  def set_visible_range(socket, chart_id, from, to) do
    push_event(socket, event_name(chart_id, :set_visible_range), %{
      from: Encoder.encode_time(from),
      to: Encoder.encode_time(to)
    })
  end

  @doc """
  Sets markers on a series.

  Pass a list of `LightweightCharts.Marker` structs or maps with
  `:time`, `:position`, `:shape`, `:color`, and optionally `:text`.
  """
  @spec set_markers(Phoenix.LiveView.Socket.t(), String.t(), String.t(), list()) ::
          Phoenix.LiveView.Socket.t()
  def set_markers(socket, chart_id, series_id, markers) do
    push_event(socket, event_name(chart_id, :set_markers), %{
      series_id: series_id,
      markers: Enum.map(markers, &Encoder.encode/1)
    })
  end

  @doc false
  def event_name(chart_id, action), do: "lc:#{chart_id}:#{action}"

  @doc false
  def encode_data_points(data) when is_list(data), do: Enum.map(data, &encode_data_point/1)

  @doc false
  def encode_data_point(point) when is_map(point) do
    point
    |> Enum.into(%{}, fn
      {:time, v} -> {"time", Encoder.encode_time(v)}
      {k, v} -> {Encoder.to_camel_case(k), v}
    end)
  end
end
