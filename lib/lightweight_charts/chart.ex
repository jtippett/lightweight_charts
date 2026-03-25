defmodule LightweightCharts.Chart do
  @moduledoc """
  Top-level chart configuration builder.

  Build chart configuration by composing options via pipeline:

      Chart.new()
      |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      |> Chart.grid(vert_lines_visible: false)
      |> Chart.crosshair(mode: :magnet)
      |> Chart.time_scale(time_visible: true)
      |> Chart.add_series(Series.candlestick(id: "candles", up_color: "#26a69a"))
      |> Chart.on(:click)

  The resulting struct is passed to the LiveView component, which
  encodes it to JSON for the JavaScript hook.
  """

  alias LightweightCharts.{Layout, Grid, Crosshair, TimeScale, PriceScale, Series, Encoder}

  defstruct [
    :layout,
    :grid,
    :crosshair,
    :time_scale,
    :right_price_scale,
    :left_price_scale,
    :auto_size,
    :width,
    :height,
    series: [],
    events: []
  ]

  @type t :: %__MODULE__{
          layout: Layout.t() | nil,
          grid: Grid.t() | nil,
          crosshair: Crosshair.t() | nil,
          time_scale: TimeScale.t() | nil,
          right_price_scale: PriceScale.t() | nil,
          left_price_scale: PriceScale.t() | nil,
          auto_size: boolean() | nil,
          width: number() | nil,
          height: number() | nil,
          series: [Series.t()],
          events: [atom()]
        }

  @event_names %{
    click: "click",
    dbl_click: "dblClick",
    crosshair_move: "crosshairMove",
    visible_range_change: "visibleTimeRangeChange"
  }

  @doc "Creates a new empty chart configuration."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Sets layout options."
  @spec layout(t(), keyword()) :: t()
  def layout(%__MODULE__{} = chart, opts), do: %{chart | layout: Layout.new(opts)}

  @doc "Sets grid options."
  @spec grid(t(), keyword()) :: t()
  def grid(%__MODULE__{} = chart, opts), do: %{chart | grid: Grid.new(opts)}

  @doc "Sets crosshair options."
  @spec crosshair(t(), keyword()) :: t()
  def crosshair(%__MODULE__{} = chart, opts), do: %{chart | crosshair: Crosshair.new(opts)}

  @doc "Sets time scale options."
  @spec time_scale(t(), keyword()) :: t()
  def time_scale(%__MODULE__{} = chart, opts), do: %{chart | time_scale: TimeScale.new(opts)}

  @doc "Sets right price scale options."
  @spec right_price_scale(t(), keyword()) :: t()
  def right_price_scale(%__MODULE__{} = chart, opts),
    do: %{chart | right_price_scale: PriceScale.new(opts)}

  @doc "Sets left price scale options."
  @spec left_price_scale(t(), keyword()) :: t()
  def left_price_scale(%__MODULE__{} = chart, opts),
    do: %{chart | left_price_scale: PriceScale.new(opts)}

  @doc "Adds a series to the chart."
  @spec add_series(t(), Series.t()) :: t()
  def add_series(%__MODULE__{} = chart, %Series{} = series),
    do: %{chart | series: chart.series ++ [series]}

  @doc """
  Subscribes to a chart interaction event.

  Events are forwarded from the JS hook to your LiveView as `handle_event` calls
  with the `lc:` prefix.

  ## Supported events

  - `:click` — Mouse click on chart
  - `:dbl_click` — Double click
  - `:crosshair_move` — Crosshair position changed
  - `:visible_range_change` — Visible time range changed
  """
  @spec on(t(), atom()) :: t()
  def on(%__MODULE__{} = chart, event) when is_map_key(@event_names, event),
    do: %{chart | events: chart.events ++ [event]}

  @doc """
  Converts the chart configuration to a JSON-compatible map.

  This is called internally by the LiveView component. You can also
  use it to inspect the generated configuration.
  """
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = chart) do
    %{}
    |> Encoder.maybe_put("layout", chart.layout && Encoder.encode(chart.layout))
    |> Encoder.maybe_put("grid", chart.grid && Encoder.encode(chart.grid))
    |> Encoder.maybe_put("crosshair", chart.crosshair && Encoder.encode(chart.crosshair))
    |> Encoder.maybe_put("timeScale", chart.time_scale && Encoder.encode(chart.time_scale))
    |> Encoder.maybe_put(
      "rightPriceScale",
      chart.right_price_scale && Encoder.encode(chart.right_price_scale)
    )
    |> Encoder.maybe_put(
      "leftPriceScale",
      chart.left_price_scale && Encoder.encode(chart.left_price_scale)
    )
    |> Encoder.maybe_put("autoSize", chart.auto_size)
    |> Encoder.maybe_put("width", chart.width)
    |> Encoder.maybe_put("height", chart.height)
    |> Map.put("series", Enum.map(chart.series, &Encoder.encode/1))
    |> Map.put("events", Enum.map(chart.events, &Map.fetch!(@event_names, &1)))
  end
end
