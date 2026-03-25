defmodule LightweightCharts.PriceLine do
  @moduledoc """
  A horizontal price line displayed on a series.

  ## Examples

      PriceLine.new(price: 150.0, color: "#ff0000", line_style: :dashed, title: "Target")
  """

  defstruct [:price, :color, :line_width, :line_style, :title, :axis_label_visible, :axis_label_color]

  @type t :: %__MODULE__{
          price: number(),
          color: String.t() | nil,
          line_width: pos_integer() | nil,
          line_style: atom() | nil,
          title: String.t() | nil,
          axis_label_visible: boolean() | nil,
          axis_label_color: String.t() | nil
        }

  @doc "Creates a new PriceLine."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = pl) do
    alias LightweightCharts.Encoder

    pl
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{}, fn
      {:line_style, v} -> {"lineStyle", Encoder.encode_enum(v)}
      {k, v} -> {Encoder.to_camel_case(k), v}
    end)
  end
end
