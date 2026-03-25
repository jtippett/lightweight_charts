defmodule LightweightCharts.Series do
  @moduledoc """
  Series configuration for chart data visualization.

  Each series has a type and type-specific style options. Use the constructor
  functions to create series with the correct type.

  ## Series Types

  - `Series.line/1` — Connected data points
  - `Series.area/1` — Filled area between line and baseline
  - `Series.bar/1` — OHLC bars with open/close ticks
  - `Series.candlestick/1` — OHLC candles with wicks
  - `Series.histogram/1` — Vertical columns
  - `Series.baseline/1` — Two-colored areas above/below a base value

  ## Examples

      Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      Series.line(id: "sma", color: "#2196f3", line_width: 2)
      Series.histogram(id: "volume", color: "#26a69a", pane_index: 1)
  """

  defstruct [
    # Identity
    :type,
    :id,
    :pane_index,
    # Common options
    :title,
    :visible,
    :last_value_visible,
    :price_line_visible,
    :price_line_source,
    :price_line_width,
    :price_line_color,
    :price_line_style,
    :base_line_visible,
    :base_line_color,
    :base_line_width,
    :base_line_style,
    :price_scale_id,
    :price_format,
    # Line/Area/Baseline shared options
    :color,
    :line_color,
    :line_style,
    :line_width,
    :line_type,
    :line_visible,
    :point_markers_visible,
    :point_markers_radius,
    :crosshair_marker_visible,
    :crosshair_marker_radius,
    :crosshair_marker_border_color,
    :crosshair_marker_background_color,
    :crosshair_marker_border_width,
    :last_price_animation,
    # Area-specific
    :top_color,
    :bottom_color,
    :relative_gradient,
    :invert_filled_area,
    # Candlestick-specific
    :up_color,
    :down_color,
    :wick_visible,
    :border_visible,
    :border_color,
    :border_up_color,
    :border_down_color,
    :wick_color,
    :wick_up_color,
    :wick_down_color,
    # Bar-specific
    :open_visible,
    :thin_bars,
    # Histogram-specific
    :base,
    # Baseline-specific
    :base_value,
    :top_fill_color1,
    :top_fill_color2,
    :top_line_color,
    :bottom_fill_color1,
    :bottom_fill_color2,
    :bottom_line_color
  ]

  @type series_type :: :line | :area | :bar | :candlestick | :histogram | :baseline
  @type t :: %__MODULE__{type: series_type(), id: String.t()}

  @type_name_map %{
    line: "Line",
    area: "Area",
    bar: "Bar",
    candlestick: "Candlestick",
    histogram: "Histogram",
    baseline: "Baseline"
  }

  # Fields that go at the top level of the encoded output, not inside "options"
  @identity_fields [:type, :id, :pane_index]

  # Fields that need enum encoding
  @enum_fields [
    :line_style,
    :line_type,
    :last_price_animation,
    :price_line_source,
    :price_line_style,
    :base_line_style
  ]

  @doc "Creates a line series."
  @spec line(keyword()) :: t()
  def line(opts \\ []), do: struct(__MODULE__, [{:type, :line} | opts])

  @doc "Creates an area series."
  @spec area(keyword()) :: t()
  def area(opts \\ []), do: struct(__MODULE__, [{:type, :area} | opts])

  @doc "Creates a bar series."
  @spec bar(keyword()) :: t()
  def bar(opts \\ []), do: struct(__MODULE__, [{:type, :bar} | opts])

  @doc "Creates a candlestick series."
  @spec candlestick(keyword()) :: t()
  def candlestick(opts \\ []), do: struct(__MODULE__, [{:type, :candlestick} | opts])

  @doc "Creates a histogram series."
  @spec histogram(keyword()) :: t()
  def histogram(opts \\ []), do: struct(__MODULE__, [{:type, :histogram} | opts])

  @doc "Creates a baseline series."
  @spec baseline(keyword()) :: t()
  def baseline(opts \\ []), do: struct(__MODULE__, [{:type, :baseline} | opts])

  @doc false
  def to_map(%__MODULE__{} = series) do
    alias LightweightCharts.Encoder

    options =
      series
      |> Map.from_struct()
      |> Enum.reject(fn {k, v} -> is_nil(v) or k in @identity_fields end)
      |> Enum.into(%{}, fn {k, v} ->
        v = if k in @enum_fields, do: Encoder.encode_enum(v), else: v
        {Encoder.to_camel_case(k), v}
      end)

    result = %{"type" => Map.fetch!(@type_name_map, series.type), "id" => series.id}

    result =
      if series.pane_index, do: Map.put(result, "paneIndex", series.pane_index), else: result

    result = if options != %{}, do: Map.put(result, "options", options), else: result
    result
  end
end
