defmodule LightweightCharts.Grid do
  @moduledoc """
  Grid line options for vertical and horizontal lines displayed on the chart.

  ## Examples

      Grid.new(vert_lines_visible: false, horz_lines_color: "#333")
  """

  defstruct [
    :vert_lines_visible,
    :vert_lines_color,
    :vert_lines_style,
    :horz_lines_visible,
    :horz_lines_color,
    :horz_lines_style
  ]

  @type t :: %__MODULE__{
          vert_lines_visible: boolean() | nil,
          vert_lines_color: String.t() | nil,
          vert_lines_style: atom() | nil,
          horz_lines_visible: boolean() | nil,
          horz_lines_color: String.t() | nil,
          horz_lines_style: atom() | nil
        }

  @doc "Creates a new Grid with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = grid) do
    alias LightweightCharts.Encoder

    vert =
      %{}
      |> maybe_put("visible", grid.vert_lines_visible)
      |> maybe_put("color", grid.vert_lines_color)
      |> maybe_put("style", grid.vert_lines_style && Encoder.encode_enum(grid.vert_lines_style))

    horz =
      %{}
      |> maybe_put("visible", grid.horz_lines_visible)
      |> maybe_put("color", grid.horz_lines_color)
      |> maybe_put("style", grid.horz_lines_style && Encoder.encode_enum(grid.horz_lines_style))

    %{}
    |> maybe_put("vertLines", if(vert == %{}, do: nil, else: vert))
    |> maybe_put("horzLines", if(horz == %{}, do: nil, else: horz))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
