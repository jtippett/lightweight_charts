defmodule LightweightCharts.PriceScale do
  @moduledoc """
  Price scale (vertical axis) options.

  ## Modes

  - `:normal` — Standard linear scale
  - `:logarithmic` — Logarithmic scale
  - `:percentage` — Percentage change from first visible value
  - `:indexed_to_100` — Indexed to 100 from first visible value

  ## Examples

      PriceScale.new(mode: :logarithmic, visible: true)
  """

  defstruct [
    :auto_scale,
    :mode,
    :invert_scale,
    :align_labels,
    :border_visible,
    :border_color,
    :entire_text_only,
    :visible,
    :ticks_visible,
    :scale_margin_top,
    :scale_margin_bottom,
    :minimum_width
  ]

  @type t :: %__MODULE__{
          auto_scale: boolean() | nil,
          mode: :normal | :logarithmic | :percentage | :indexed_to_100 | nil,
          invert_scale: boolean() | nil,
          align_labels: boolean() | nil,
          border_visible: boolean() | nil,
          border_color: String.t() | nil,
          entire_text_only: boolean() | nil,
          visible: boolean() | nil,
          ticks_visible: boolean() | nil,
          scale_margin_top: float() | nil,
          scale_margin_bottom: float() | nil,
          minimum_width: number() | nil
        }

  @doc "Creates a new PriceScale with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = ps) do
    alias LightweightCharts.Encoder

    map = %{}
    map = maybe_put(map, "autoScale", ps.auto_scale)
    map = maybe_put(map, "mode", ps.mode && Encoder.encode_enum(ps.mode))
    map = maybe_put(map, "invertScale", ps.invert_scale)
    map = maybe_put(map, "alignLabels", ps.align_labels)
    map = maybe_put(map, "borderVisible", ps.border_visible)
    map = maybe_put(map, "borderColor", ps.border_color)
    map = maybe_put(map, "entireTextOnly", ps.entire_text_only)
    map = maybe_put(map, "visible", ps.visible)
    map = maybe_put(map, "ticksVisible", ps.ticks_visible)
    map = maybe_put(map, "minimumWidth", ps.minimum_width)

    margins =
      %{}
      |> maybe_put("top", ps.scale_margin_top)
      |> maybe_put("bottom", ps.scale_margin_bottom)

    map = maybe_put(map, "scaleMargins", if(margins == %{}, do: nil, else: margins))

    map
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
