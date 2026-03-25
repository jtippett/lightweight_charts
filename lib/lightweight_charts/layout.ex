defmodule LightweightCharts.Layout do
  @moduledoc """
  Layout options for chart appearance.

  Controls background color, text color, and font settings.

  ## Examples

      Layout.new(background_color: "#1a1a2e", text_color: "#e0e0e0", font_size: 14)
  """

  defstruct [:background_color, :text_color, :font_size, :font_family, :attribution_logo]

  @type t :: %__MODULE__{
          background_color: String.t() | nil,
          text_color: String.t() | nil,
          font_size: pos_integer() | nil,
          font_family: String.t() | nil,
          attribution_logo: boolean() | nil
        }

  @doc "Creates a new Layout with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = layout) do
    map = %{}

    map =
      if layout.background_color do
        Map.put(map, "background", %{"type" => "solid", "color" => layout.background_color})
      else
        map
      end

    map = if layout.text_color, do: Map.put(map, "textColor", layout.text_color), else: map
    map = if layout.font_size, do: Map.put(map, "fontSize", layout.font_size), else: map
    map = if layout.font_family, do: Map.put(map, "fontFamily", layout.font_family), else: map

    map =
      if not is_nil(layout.attribution_logo),
        do: Map.put(map, "attributionLogo", layout.attribution_logo),
        else: map

    map
  end
end
