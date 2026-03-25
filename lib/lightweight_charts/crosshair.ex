defmodule LightweightCharts.Crosshair do
  @moduledoc """
  Crosshair options controlling the appearance and behavior of the chart crosshair.

  ## Modes

  - `:normal` — Crosshair moves freely
  - `:magnet` — Crosshair snaps to data points
  - `:hidden` — Crosshair not displayed
  - `:magnet_ohlc` — Snaps to OHLC values

  ## Examples

      Crosshair.new(mode: :magnet, vert_line_color: "#999")
  """

  defstruct [
    :mode,
    :vert_line_color,
    :vert_line_width,
    :vert_line_style,
    :vert_line_visible,
    :vert_line_label_visible,
    :vert_line_label_background_color,
    :horz_line_color,
    :horz_line_width,
    :horz_line_style,
    :horz_line_visible,
    :horz_line_label_visible,
    :horz_line_label_background_color
  ]

  @type t :: %__MODULE__{
          mode: :normal | :magnet | :hidden | :magnet_ohlc | nil,
          vert_line_color: String.t() | nil,
          vert_line_width: pos_integer() | nil,
          vert_line_style: atom() | nil,
          vert_line_visible: boolean() | nil,
          vert_line_label_visible: boolean() | nil,
          vert_line_label_background_color: String.t() | nil,
          horz_line_color: String.t() | nil,
          horz_line_width: pos_integer() | nil,
          horz_line_style: atom() | nil,
          horz_line_visible: boolean() | nil,
          horz_line_label_visible: boolean() | nil,
          horz_line_label_background_color: String.t() | nil
        }

  @doc "Creates a new Crosshair with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = ch) do
    alias LightweightCharts.Encoder

    vert =
      %{}
      |> Encoder.maybe_put("color", ch.vert_line_color)
      |> Encoder.maybe_put("width", ch.vert_line_width)
      |> Encoder.maybe_put("style", ch.vert_line_style && Encoder.encode_enum(ch.vert_line_style))
      |> Encoder.maybe_put("visible", ch.vert_line_visible)
      |> Encoder.maybe_put("labelVisible", ch.vert_line_label_visible)
      |> Encoder.maybe_put("labelBackgroundColor", ch.vert_line_label_background_color)

    horz =
      %{}
      |> Encoder.maybe_put("color", ch.horz_line_color)
      |> Encoder.maybe_put("width", ch.horz_line_width)
      |> Encoder.maybe_put("style", ch.horz_line_style && Encoder.encode_enum(ch.horz_line_style))
      |> Encoder.maybe_put("visible", ch.horz_line_visible)
      |> Encoder.maybe_put("labelVisible", ch.horz_line_label_visible)
      |> Encoder.maybe_put("labelBackgroundColor", ch.horz_line_label_background_color)

    %{}
    |> Encoder.maybe_put("mode", ch.mode && Encoder.encode_enum(ch.mode))
    |> Encoder.maybe_put("vertLine", if(vert == %{}, do: nil, else: vert))
    |> Encoder.maybe_put("horzLine", if(horz == %{}, do: nil, else: horz))
  end
end
