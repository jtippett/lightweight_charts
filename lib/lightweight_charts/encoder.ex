defmodule LightweightCharts.Encoder do
  @moduledoc """
  Converts Elixir chart configuration to camelCase JSON-compatible maps.

  Handles snake_case to camelCase key conversion, time format encoding,
  nil stripping, and enum value mapping.
  """

  @line_styles %{
    solid: 0,
    dotted: 1,
    dashed: 2,
    large_dashed: 3,
    sparse_dotted: 4
  }

  @line_types %{
    simple: 0,
    with_steps: 1,
    curved: 2
  }

  @crosshair_modes %{
    normal: 0,
    magnet: 1,
    hidden: 2,
    magnet_ohlc: 3
  }

  @price_scale_modes %{
    normal: 0,
    logarithmic: 1,
    percentage: 2,
    indexed_to_100: 3
  }

  @last_price_animations %{
    disabled: 0,
    continuous: 1,
    on_data_update: 2
  }

  @price_line_sources %{
    last_bar: 0,
    last_visible: 1
  }

  @enums Map.merge(@line_styles, @line_types)
         |> Map.merge(@crosshair_modes)
         |> Map.merge(@price_scale_modes)
         |> Map.merge(@last_price_animations)
         |> Map.merge(@price_line_sources)

  @doc """
  Converts a snake_case atom or string to a camelCase string.

  ## Examples

      iex> LightweightCharts.Encoder.to_camel_case(:background_color)
      "backgroundColor"

      iex> LightweightCharts.Encoder.to_camel_case(:color)
      "color"
  """
  @spec to_camel_case(atom() | String.t()) :: String.t()
  def to_camel_case(key) when is_atom(key), do: to_camel_case(Atom.to_string(key))

  def to_camel_case(key) when is_binary(key) do
    case String.split(key, "_") do
      [single] -> single
      [head | tail] -> head <> Enum.map_join(tail, &String.capitalize/1)
    end
  end

  @doc """
  Encodes an Elixir map, list, or scalar to a JSON-compatible structure
  with camelCase keys and nil values stripped.
  """
  @spec encode(term()) :: term()

  # Custom struct clauses — must come before the generic struct clause
  def encode(%LightweightCharts.Layout{} = layout), do: LightweightCharts.Layout.to_map(layout)
  def encode(%LightweightCharts.Grid{} = grid), do: LightweightCharts.Grid.to_map(grid)
  def encode(%LightweightCharts.Crosshair{} = ch), do: LightweightCharts.Crosshair.to_map(ch)
  def encode(%LightweightCharts.PriceScale{} = ps), do: LightweightCharts.PriceScale.to_map(ps)
  def encode(%LightweightCharts.Series{} = s), do: LightweightCharts.Series.to_map(s)
  def encode(%LightweightCharts.PriceLine{} = pl), do: LightweightCharts.PriceLine.to_map(pl)
  def encode(%LightweightCharts.Marker{} = m), do: LightweightCharts.Marker.to_map(m)

  # Generic struct clause
  def encode(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> encode()
  end

  def encode(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{}, fn {k, v} -> {to_camel_case(k), encode(v)} end)
  end

  def encode(list) when is_list(list), do: Enum.map(list, &encode/1)
  def encode(value), do: value

  @doc """
  Encodes time values to the format lightweight-charts expects.

  - `DateTime`/`NaiveDateTime` -> Unix timestamp (integer)
  - `Date` -> `"YYYY-MM-DD"` string
  - Integer -> passed through
  - String -> passed through
  """
  @spec encode_time(DateTime.t() | NaiveDateTime.t() | Date.t() | integer() | String.t()) ::
          integer() | String.t()
  def encode_time(%DateTime{} = dt), do: DateTime.to_unix(dt)

  def encode_time(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()

  def encode_time(%Date{} = d), do: Date.to_iso8601(d)
  def encode_time(value) when is_integer(value), do: value
  def encode_time(value) when is_binary(value), do: value

  @doc """
  Converts an Elixir atom to its lightweight-charts enum integer value.

  ## Supported enums

  Line styles: `:solid` (0), `:dotted` (1), `:dashed` (2), `:large_dashed` (3), `:sparse_dotted` (4)

  Line types: `:simple` (0), `:with_steps` (1), `:curved` (2)

  Crosshair modes: `:normal` (0), `:magnet` (1), `:hidden` (2), `:magnet_ohlc` (3)

  Price scale modes: `:normal` (0), `:logarithmic` (1), `:percentage` (2), `:indexed_to_100` (3)
  """
  @spec encode_enum(atom()) :: integer()
  def encode_enum(value) when is_atom(value) do
    Map.fetch!(@enums, value)
  end

  @doc """
  Puts a key-value pair into a map only if the value is not nil.

  Returns the map unchanged when value is nil, otherwise adds the entry.

  ## Examples

      iex> LightweightCharts.Encoder.maybe_put(%{}, "color", "#fff")
      %{"color" => "#fff"}

      iex> LightweightCharts.Encoder.maybe_put(%{}, "color", nil)
      %{}
  """
  @spec maybe_put(map(), any(), any()) :: map()
  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)
end
