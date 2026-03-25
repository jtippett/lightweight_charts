defmodule LightweightCharts.Marker do
  @moduledoc """
  Series markers — visual indicators placed on data points.

  ## Positions

  - `:above_bar` — Above the data point
  - `:below_bar` — Below the data point
  - `:in_bar` — On the data point

  ## Shapes

  - `:arrow_up`, `:arrow_down` — Arrow indicators
  - `:circle` — Circle marker
  - `:square` — Square marker

  ## Examples

      Marker.new(time: ~U[2024-01-15 00:00:00Z], position: :above_bar, shape: :arrow_up, color: "#26a69a", text: "Buy")
  """

  defstruct [:time, :position, :shape, :color, :text, :size, :id]

  @type t :: %__MODULE__{
          time: DateTime.t() | NaiveDateTime.t() | Date.t() | integer() | String.t(),
          position: :above_bar | :below_bar | :in_bar,
          shape: :arrow_up | :arrow_down | :circle | :square,
          color: String.t(),
          text: String.t() | nil,
          size: number() | nil,
          id: String.t() | nil
        }

  @positions %{above_bar: "aboveBar", below_bar: "belowBar", in_bar: "inBar"}
  @shapes %{arrow_up: "arrowUp", arrow_down: "arrowDown", circle: "circle", square: "square"}

  @doc "Creates a new Marker."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)

  @doc false
  def to_map(%__MODULE__{} = m) do
    alias LightweightCharts.Encoder

    %{"time" => Encoder.encode_time(m.time)}
    |> maybe_put("position", m.position && Map.fetch!(@positions, m.position))
    |> maybe_put("shape", m.shape && Map.fetch!(@shapes, m.shape))
    |> maybe_put("color", m.color)
    |> maybe_put("text", m.text)
    |> maybe_put("size", m.size)
    |> maybe_put("id", m.id)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
