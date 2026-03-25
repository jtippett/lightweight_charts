# lightweight_charts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build `lightweight_charts`, an Elixir package wrapping TradingView's lightweight-charts v5.1.0 for Phoenix LiveView with declarative structs, a bundled JS hook, and bidirectional events.

**Architecture:** Three layers — pure Elixir config structs (no Phoenix dep), a LiveView integration layer (function component + event helpers), and a vendored JS hook. Data flows as: Elixir structs -> JSON -> push_event -> JS hook -> lightweight-charts API, with interaction events flowing back via pushEvent -> handle_event.

**Tech Stack:** Elixir 1.19+, Phoenix LiveView 1.0+, Jason, lightweight-charts v5.1.0 (vendored JS), esbuild (for bundling the hook).

**Design doc:** `docs/plans/2026-03-25-lightweight-charts-design.md`

---

### Task 1: Project Scaffolding

**Files:**
- Create: `mix.exs`
- Create: `lib/lightweight_charts.ex`
- Create: `test/test_helper.exs`
- Create: `.formatter.exs`
- Create: `LICENSE`

**Step 1: Initialize the mix project**

Run:
```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex
mix new lightweight_charts --module LightweightCharts
```

This creates the standard mix project skeleton. We'll then customize `mix.exs`.

**Step 2: Update mix.exs with dependencies and package metadata**

Replace the generated `mix.exs` with:

```elixir
defmodule LightweightCharts.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/user/lightweight_charts"

  def project do
    [
      app: :lightweight_charts,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "LightweightCharts",
      description: "TradingView Lightweight Charts for Phoenix LiveView",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv assets mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "LightweightCharts",
      extras: ["README.md"],
      groups_for_modules: [
        "Chart Configuration": [
          LightweightCharts.Chart,
          LightweightCharts.Series,
          LightweightCharts.Layout,
          LightweightCharts.Grid,
          LightweightCharts.Crosshair,
          LightweightCharts.TimeScale,
          LightweightCharts.PriceScale,
          LightweightCharts.PriceLine,
          LightweightCharts.Marker
        ],
        "LiveView Integration": [
          LightweightCharts.Live.ChartComponent,
          LightweightCharts.Live.Helpers
        ],
        Encoding: [
          LightweightCharts.Encoder
        ]
      ]
    ]
  end
end
```

**Step 3: Update the main module with a placeholder**

Replace `lib/lightweight_charts.ex` with:

```elixir
defmodule LightweightCharts do
  @moduledoc """
  TradingView Lightweight Charts for Phoenix LiveView.

  Provides declarative chart configuration via Elixir structs and a
  bundled JavaScript hook for rendering interactive financial charts.

  ## Quick Start

      chart =
        LightweightCharts.Chart.new()
        |> LightweightCharts.Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> LightweightCharts.Chart.add_series(
          LightweightCharts.Series.candlestick(id: "candles", up_color: "#26a69a")
        )

  See `LightweightCharts.Chart` for the full builder API and
  `LightweightCharts.Live.ChartComponent` for LiveView integration.
  """
end
```

**Step 4: Install dependencies**

Run:
```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts
mix deps.get
```

**Step 5: Run the tests to verify scaffold works**

Run: `mix test`
Expected: 0 tests, 0 failures (the generated test has a placeholder we should remove)

**Step 6: Replace the generated test with an empty helper**

Replace `test/lightweight_charts_test.exs` with an empty file (we'll add real tests per module later):

```elixir
defmodule LightweightChartsTest do
  use ExUnit.Case
end
```

Run: `mix test`
Expected: 0 tests, 0 failures

**Step 7: Add the Apache 2.0 LICENSE file**

Create `LICENSE` with the standard Apache 2.0 text.

**Step 8: Commit**

```bash
git add lightweight_charts/
git commit -m "feat: scaffold lightweight_charts mix project"
```

---

### Task 2: Encoder Module

The encoder converts Elixir snake_case atoms to camelCase strings and handles struct-to-map conversion for JSON serialization. This is foundational — every other module depends on it.

**Files:**
- Create: `lib/lightweight_charts/encoder.ex`
- Create: `test/lightweight_charts/encoder_test.exs`

**Step 1: Write the failing tests**

Create `test/lightweight_charts/encoder_test.exs`:

```elixir
defmodule LightweightCharts.EncoderTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Encoder

  describe "to_camel_case/1" do
    test "converts snake_case atom to camelCase string" do
      assert Encoder.to_camel_case(:background_color) == "backgroundColor"
      assert Encoder.to_camel_case(:up_color) == "upColor"
      assert Encoder.to_camel_case(:line_width) == "lineWidth"
    end

    test "single word stays lowercase" do
      assert Encoder.to_camel_case(:color) == "color"
      assert Encoder.to_camel_case(:visible) == "visible"
    end

    test "converts string keys" do
      assert Encoder.to_camel_case("bar_spacing") == "barSpacing"
    end
  end

  describe "encode/1" do
    test "converts a flat map with atom keys to camelCase string keys" do
      input = %{up_color: "#26a69a", down_color: "#ef5350", wick_visible: true}

      result = Encoder.encode(input)

      assert result == %{
               "upColor" => "#26a69a",
               "downColor" => "#ef5350",
               "wickVisible" => true
             }
    end

    test "converts nested maps" do
      input = %{
        layout: %{background_color: "#fff", text_color: "#000"},
        time_scale: %{time_visible: true}
      }

      result = Encoder.encode(input)

      assert result == %{
               "layout" => %{"backgroundColor" => "#fff", "textColor" => "#000"},
               "timeScale" => %{"timeVisible" => true}
             }
    end

    test "passes through scalar values unchanged" do
      assert Encoder.encode("hello") == "hello"
      assert Encoder.encode(42) == 42
      assert Encoder.encode(true) == true
      assert Encoder.encode(nil) == nil
    end

    test "converts lists of maps" do
      input = [%{line_width: 2}, %{line_width: 3}]
      result = Encoder.encode(input)
      assert result == [%{"lineWidth" => 2}, %{"lineWidth" => 3}]
    end

    test "strips nil values from maps" do
      input = %{color: "#fff", line_width: nil, visible: true}
      result = Encoder.encode(input)
      assert result == %{"color" => "#fff", "visible" => true}
    end

    test "converts DateTime to Unix timestamp" do
      dt = ~U[2024-01-15 12:30:00Z]
      assert Encoder.encode_time(dt) == 1705318200
    end

    test "converts NaiveDateTime to Unix timestamp" do
      ndt = ~N[2024-01-15 12:30:00]
      assert Encoder.encode_time(ndt) == 1705318200
    end

    test "converts Date to YYYY-MM-DD string" do
      d = ~D[2024-01-15]
      assert Encoder.encode_time(d) == "2024-01-15"
    end

    test "passes through integers as Unix timestamps" do
      assert Encoder.encode_time(1705318200) == 1705318200
    end

    test "passes through YYYY-MM-DD strings" do
      assert Encoder.encode_time("2024-01-15") == "2024-01-15"
    end

    test "converts atoms to lowercase strings for enum values" do
      assert Encoder.encode_enum(:solid) == 0
      assert Encoder.encode_enum(:dotted) == 1
      assert Encoder.encode_enum(:dashed) == 2
      assert Encoder.encode_enum(:large_dashed) == 3
      assert Encoder.encode_enum(:sparse_dotted) == 4
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `mix test test/lightweight_charts/encoder_test.exs`
Expected: Compilation error — `LightweightCharts.Encoder` module not found

**Step 3: Implement the Encoder**

Create `lib/lightweight_charts/encoder.ex`:

```elixir
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
  def encode_time(%NaiveDateTime{} = ndt), do: ndt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
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
end
```

**Step 4: Run tests to verify they pass**

Run: `mix test test/lightweight_charts/encoder_test.exs`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/lightweight_charts/encoder.ex test/lightweight_charts/encoder_test.exs
git commit -m "feat: add Encoder module for snake_case to camelCase conversion"
```

---

### Task 3: Layout Struct

**Files:**
- Create: `lib/lightweight_charts/layout.ex`
- Create: `test/lightweight_charts/layout_test.exs`

**Step 1: Write the failing test**

Create `test/lightweight_charts/layout_test.exs`:

```elixir
defmodule LightweightCharts.LayoutTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Layout
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates layout with defaults" do
      layout = Layout.new()
      assert layout.background_color == nil
      assert layout.text_color == nil
      assert layout.font_size == nil
      assert layout.font_family == nil
    end

    test "creates layout with custom options" do
      layout = Layout.new(background_color: "#1a1a2e", text_color: "#e0e0e0", font_size: 14)
      assert layout.background_color == "#1a1a2e"
      assert layout.text_color == "#e0e0e0"
      assert layout.font_size == 14
    end
  end

  describe "encoding" do
    test "encodes to camelCase JSON map" do
      layout = Layout.new(background_color: "#1a1a2e", text_color: "#e0e0e0")
      encoded = Encoder.encode(layout)

      assert encoded == %{
               "background" => %{"type" => "solid", "color" => "#1a1a2e"},
               "textColor" => "#e0e0e0"
             }
    end

    test "strips nil fields" do
      layout = Layout.new(text_color: "#000")
      encoded = Encoder.encode(layout)

      assert encoded == %{"textColor" => "#000"}
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `mix test test/lightweight_charts/layout_test.exs`
Expected: Compilation error

**Step 3: Implement Layout**

Create `lib/lightweight_charts/layout.ex`:

```elixir
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
end

defimpl Jason.Encoder, for: LightweightCharts.Layout do
  def encode(layout, opts) do
    layout
    |> LightweightCharts.Layout.to_map()
    |> Jason.Encode.map(opts)
  end
end
```

We also need a `to_map/1` function that handles the `background_color` -> `background: {type: "solid", color: ...}` transform. Update the module:

```elixir
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
```

Note: The `background_color` field maps to `{background: {type: "solid", color: value}}` in the JS API — not a simple key rename. This is why Layout needs custom encoding rather than relying on the generic Encoder.

**Step 4: Run tests**

Run: `mix test test/lightweight_charts/layout_test.exs`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/lightweight_charts/layout.ex test/lightweight_charts/layout_test.exs
git commit -m "feat: add Layout struct with background color encoding"
```

---

### Task 4: Grid Struct

**Files:**
- Create: `lib/lightweight_charts/grid.ex`
- Create: `test/lightweight_charts/grid_test.exs`

**Step 1: Write the failing test**

```elixir
defmodule LightweightCharts.GridTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Grid
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates grid with defaults (all nil)" do
      grid = Grid.new()
      assert grid.vert_lines_visible == nil
      assert grid.horz_lines_visible == nil
    end

    test "accepts all options" do
      grid =
        Grid.new(
          vert_lines_visible: false,
          vert_lines_color: "#333",
          vert_lines_style: :dashed,
          horz_lines_visible: true,
          horz_lines_color: "#444",
          horz_lines_style: :dotted
        )

      assert grid.vert_lines_visible == false
      assert grid.vert_lines_color == "#333"
      assert grid.vert_lines_style == :dashed
    end
  end

  describe "encoding" do
    test "encodes to nested vertLines/horzLines structure" do
      grid = Grid.new(vert_lines_visible: false, horz_lines_color: "#444")
      encoded = Encoder.encode(grid)

      assert encoded == %{
               "vertLines" => %{"visible" => false},
               "horzLines" => %{"color" => "#444"}
             }
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `mix test test/lightweight_charts/grid_test.exs`

**Step 3: Implement Grid**

Create `lib/lightweight_charts/grid.ex`:

```elixir
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
end
```

The `Encoder.encode/1` needs special handling for Grid since it nests under `vertLines`/`horzLines`. Add a custom encoding clause. The simplest approach: implement the `encode` protocol on the struct by defining a `to_map/1`:

Add to `lib/lightweight_charts/grid.ex`:

```elixir
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
```

Since Grid and Layout both need custom encoding (they don't map 1:1 to camelCase), we need the `Encoder.encode/1` to detect these structs. Update `Encoder.encode/1`:

```elixir
  def encode(%LightweightCharts.Layout{} = layout), do: LightweightCharts.Layout.to_map(layout)
  def encode(%LightweightCharts.Grid{} = grid), do: LightweightCharts.Grid.to_map(grid)
```

Place these clauses **before** the generic struct clause.

**Step 4: Run tests**

Run: `mix test test/lightweight_charts/grid_test.exs`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/lightweight_charts/grid.ex test/lightweight_charts/grid_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add Grid struct with nested vertLines/horzLines encoding"
```

---

### Task 5: Crosshair Struct

**Files:**
- Create: `lib/lightweight_charts/crosshair.ex`
- Create: `test/lightweight_charts/crosshair_test.exs`

**Step 1: Write failing test**

```elixir
defmodule LightweightCharts.CrosshairTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Crosshair
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates crosshair with mode" do
      ch = Crosshair.new(mode: :magnet)
      assert ch.mode == :magnet
    end

    test "accepts vert/horz line options" do
      ch = Crosshair.new(
        mode: :normal,
        vert_line_color: "#999",
        vert_line_width: 2,
        vert_line_style: :dashed,
        vert_line_visible: true,
        vert_line_label_visible: false,
        horz_line_color: "#aaa"
      )

      assert ch.vert_line_color == "#999"
      assert ch.horz_line_color == "#aaa"
    end
  end

  describe "encoding" do
    test "encodes mode to integer and nests line options" do
      ch = Crosshair.new(mode: :magnet, vert_line_color: "#999", horz_line_visible: false)
      encoded = Encoder.encode(ch)

      assert encoded["mode"] == 1
      assert encoded["vertLine"]["color"] == "#999"
      assert encoded["horzLine"]["visible"] == false
    end
  end
end
```

**Step 2: Run tests — expect failure**

**Step 3: Implement Crosshair**

Create `lib/lightweight_charts/crosshair.ex`:

```elixir
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
      |> maybe_put("color", ch.vert_line_color)
      |> maybe_put("width", ch.vert_line_width)
      |> maybe_put("style", ch.vert_line_style && Encoder.encode_enum(ch.vert_line_style))
      |> maybe_put("visible", ch.vert_line_visible)
      |> maybe_put("labelVisible", ch.vert_line_label_visible)
      |> maybe_put("labelBackgroundColor", ch.vert_line_label_background_color)

    horz =
      %{}
      |> maybe_put("color", ch.horz_line_color)
      |> maybe_put("width", ch.horz_line_width)
      |> maybe_put("style", ch.horz_line_style && Encoder.encode_enum(ch.horz_line_style))
      |> maybe_put("visible", ch.horz_line_visible)
      |> maybe_put("labelVisible", ch.horz_line_label_visible)
      |> maybe_put("labelBackgroundColor", ch.horz_line_label_background_color)

    %{}
    |> maybe_put("mode", ch.mode && Encoder.encode_enum(ch.mode))
    |> maybe_put("vertLine", if(vert == %{}, do: nil, else: vert))
    |> maybe_put("horzLine", if(horz == %{}, do: nil, else: horz))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
```

Add to `Encoder.encode/1`:
```elixir
def encode(%LightweightCharts.Crosshair{} = ch), do: LightweightCharts.Crosshair.to_map(ch)
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/crosshair.ex test/lightweight_charts/crosshair_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add Crosshair struct with mode and line options"
```

---

### Task 6: TimeScale Struct

**Files:**
- Create: `lib/lightweight_charts/time_scale.ex`
- Create: `test/lightweight_charts/time_scale_test.exs`

**Step 1: Write failing test**

```elixir
defmodule LightweightCharts.TimeScaleTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.TimeScale
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates time scale with options" do
      ts = TimeScale.new(time_visible: true, bar_spacing: 8, right_offset: 5)
      assert ts.time_visible == true
      assert ts.bar_spacing == 8
      assert ts.right_offset == 5
    end
  end

  describe "encoding" do
    test "encodes to camelCase" do
      ts = TimeScale.new(time_visible: true, seconds_visible: false, bar_spacing: 10)
      encoded = Encoder.encode(ts)

      assert encoded == %{
               "timeVisible" => true,
               "secondsVisible" => false,
               "barSpacing" => 10
             }
    end
  end
end
```

**Step 2: Run test — expect failure**

**Step 3: Implement TimeScale**

Create `lib/lightweight_charts/time_scale.ex`:

```elixir
defmodule LightweightCharts.TimeScale do
  @moduledoc """
  Time scale (horizontal axis) options.

  ## Examples

      TimeScale.new(time_visible: true, bar_spacing: 10, right_offset: 5)
  """

  defstruct [
    :right_offset,
    :bar_spacing,
    :min_bar_spacing,
    :fix_left_edge,
    :fix_right_edge,
    :lock_visible_time_range_on_resize,
    :right_bar_stays_on_scroll,
    :border_visible,
    :border_color,
    :visible,
    :time_visible,
    :seconds_visible,
    :shift_visible_range_on_new_bar,
    :ticks_visible,
    :uniform_distribution,
    :minimum_height,
    :allow_bold_labels
  ]

  @type t :: %__MODULE__{
          right_offset: number() | nil,
          bar_spacing: number() | nil,
          min_bar_spacing: number() | nil,
          fix_left_edge: boolean() | nil,
          fix_right_edge: boolean() | nil,
          lock_visible_time_range_on_resize: boolean() | nil,
          right_bar_stays_on_scroll: boolean() | nil,
          border_visible: boolean() | nil,
          border_color: String.t() | nil,
          visible: boolean() | nil,
          time_visible: boolean() | nil,
          seconds_visible: boolean() | nil,
          shift_visible_range_on_new_bar: boolean() | nil,
          ticks_visible: boolean() | nil,
          uniform_distribution: boolean() | nil,
          minimum_height: number() | nil,
          allow_bold_labels: boolean() | nil
        }

  @doc "Creates a new TimeScale with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)
end
```

TimeScale fields map 1:1 via camelCase conversion — no custom `to_map` needed. The generic `Encoder.encode/1` struct clause handles it.

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/time_scale.ex test/lightweight_charts/time_scale_test.exs
git commit -m "feat: add TimeScale struct"
```

---

### Task 7: PriceScale Struct

**Files:**
- Create: `lib/lightweight_charts/price_scale.ex`
- Create: `test/lightweight_charts/price_scale_test.exs`

**Step 1: Write failing test**

```elixir
defmodule LightweightCharts.PriceScaleTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.PriceScale
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates price scale with options" do
      ps = PriceScale.new(auto_scale: true, mode: :logarithmic, visible: true)
      assert ps.auto_scale == true
      assert ps.mode == :logarithmic
    end
  end

  describe "encoding" do
    test "encodes mode as integer" do
      ps = PriceScale.new(mode: :logarithmic, visible: true, border_visible: false)
      encoded = Encoder.encode(ps)

      assert encoded["mode"] == 1
      assert encoded["visible"] == true
      assert encoded["borderVisible"] == false
    end

    test "encodes scale margins" do
      ps = PriceScale.new(scale_margin_top: 0.1, scale_margin_bottom: 0.2)
      encoded = Encoder.encode(ps)

      assert encoded["scaleMargins"] == %{"top" => 0.1, "bottom" => 0.2}
    end
  end
end
```

**Step 2: Run test — expect failure**

**Step 3: Implement PriceScale**

Create `lib/lightweight_charts/price_scale.ex`:

```elixir
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
```

Add to `Encoder.encode/1`:
```elixir
def encode(%LightweightCharts.PriceScale{} = ps), do: LightweightCharts.PriceScale.to_map(ps)
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/price_scale.ex test/lightweight_charts/price_scale_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add PriceScale struct with scale margins encoding"
```

---

### Task 8: Series Struct

This is the largest config struct. Each series type has shared options plus type-specific style options.

**Files:**
- Create: `lib/lightweight_charts/series.ex`
- Create: `test/lightweight_charts/series_test.exs`

**Step 1: Write the failing tests**

```elixir
defmodule LightweightCharts.SeriesTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Series
  alias LightweightCharts.Encoder

  describe "constructor functions" do
    test "candlestick/1 creates a candlestick series" do
      s = Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      assert s.type == :candlestick
      assert s.id == "candles"
      assert s.up_color == "#26a69a"
    end

    test "line/1 creates a line series" do
      s = Series.line(id: "sma", color: "#2196f3", line_width: 2)
      assert s.type == :line
      assert s.color == "#2196f3"
      assert s.line_width == 2
    end

    test "area/1 creates an area series" do
      s = Series.area(id: "vol", top_color: "rgba(46,220,135,0.4)", line_color: "#33D778")
      assert s.type == :area
      assert s.top_color == "rgba(46,220,135,0.4)"
    end

    test "bar/1 creates a bar series" do
      s = Series.bar(id: "ohlc", up_color: "#26a69a")
      assert s.type == :bar
    end

    test "histogram/1 creates a histogram series" do
      s = Series.histogram(id: "vol", color: "#26a69a", base: 0)
      assert s.type == :histogram
      assert s.base == 0
    end

    test "baseline/1 creates a baseline series" do
      s = Series.baseline(id: "pnl", base_value: 100.0, top_line_color: "#26a69a")
      assert s.type == :baseline
      assert s.base_value == 100.0
    end
  end

  describe "encoding" do
    test "encodes candlestick series to JS-compatible map" do
      s = Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      encoded = Encoder.encode(s)

      assert encoded["type"] == "Candlestick"
      assert encoded["id"] == "candles"
      assert encoded["options"]["upColor"] == "#26a69a"
      assert encoded["options"]["downColor"] == "#ef5350"
    end

    test "encodes line series with line style enum" do
      s = Series.line(id: "sma", color: "#2196f3", line_style: :dashed, line_type: :curved)
      encoded = Encoder.encode(s)

      assert encoded["type"] == "Line"
      assert encoded["options"]["color"] == "#2196f3"
      assert encoded["options"]["lineStyle"] == 2
      assert encoded["options"]["lineType"] == 2
    end

    test "encodes common series options" do
      s = Series.line(
        id: "sma",
        title: "SMA 20",
        visible: true,
        price_line_visible: false,
        price_scale_id: "right"
      )

      encoded = Encoder.encode(s)

      assert encoded["options"]["title"] == "SMA 20"
      assert encoded["options"]["visible"] == true
      assert encoded["options"]["priceLineVisible"] == false
      assert encoded["options"]["priceScaleId"] == "right"
    end

    test "encodes series with pane_index" do
      s = Series.histogram(id: "vol", color: "#26a69a", pane_index: 1)
      encoded = Encoder.encode(s)

      assert encoded["paneIndex"] == 1
    end
  end
end
```

**Step 2: Run tests — expect failure**

**Step 3: Implement Series**

Create `lib/lightweight_charts/series.ex`:

```elixir
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
    result = if series.pane_index, do: Map.put(result, "paneIndex", series.pane_index), else: result
    result = if options != %{}, do: Map.put(result, "options", options), else: result
    result
  end
end
```

Add to `Encoder.encode/1`:
```elixir
def encode(%LightweightCharts.Series{} = s), do: LightweightCharts.Series.to_map(s)
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/series.ex test/lightweight_charts/series_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add Series struct with all 6 series types"
```

---

### Task 9: PriceLine Struct

**Files:**
- Create: `lib/lightweight_charts/price_line.ex`
- Create: `test/lightweight_charts/price_line_test.exs`

**Step 1: Write failing test**

```elixir
defmodule LightweightCharts.PriceLineTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.PriceLine
  alias LightweightCharts.Encoder

  test "creates and encodes a price line" do
    pl = PriceLine.new(price: 150.0, color: "#ff0000", line_width: 2, line_style: :dashed, title: "Target")
    encoded = Encoder.encode(pl)

    assert encoded["price"] == 150.0
    assert encoded["color"] == "#ff0000"
    assert encoded["lineWidth"] == 2
    assert encoded["lineStyle"] == 2
    assert encoded["title"] == "Target"
  end
end
```

**Step 2: Run test — expect failure**

**Step 3: Implement PriceLine**

Create `lib/lightweight_charts/price_line.ex`:

```elixir
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
```

Add to `Encoder.encode/1`:
```elixir
def encode(%LightweightCharts.PriceLine{} = pl), do: LightweightCharts.PriceLine.to_map(pl)
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/price_line.ex test/lightweight_charts/price_line_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add PriceLine struct"
```

---

### Task 10: Marker Struct

**Files:**
- Create: `lib/lightweight_charts/marker.ex`
- Create: `test/lightweight_charts/marker_test.exs`

**Step 1: Write failing test**

```elixir
defmodule LightweightCharts.MarkerTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Marker
  alias LightweightCharts.Encoder

  test "creates and encodes a marker" do
    marker = Marker.new(
      time: ~U[2024-01-15 00:00:00Z],
      position: :above_bar,
      shape: :arrow_up,
      color: "#26a69a",
      text: "Buy"
    )

    encoded = Encoder.encode(marker)

    assert encoded["time"] == 1705276800
    assert encoded["position"] == "aboveBar"
    assert encoded["shape"] == "arrowUp"
    assert encoded["color"] == "#26a69a"
    assert encoded["text"] == "Buy"
  end

  test "encodes Date time as string" do
    marker = Marker.new(time: ~D[2024-01-15], position: :below_bar, shape: :arrow_down, color: "#f00")
    encoded = Encoder.encode(marker)

    assert encoded["time"] == "2024-01-15"
    assert encoded["position"] == "belowBar"
    assert encoded["shape"] == "arrowDown"
  end
end
```

**Step 2: Run test — expect failure**

**Step 3: Implement Marker**

Create `lib/lightweight_charts/marker.ex`:

```elixir
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
```

Add to `Encoder.encode/1`:
```elixir
def encode(%LightweightCharts.Marker{} = m), do: LightweightCharts.Marker.to_map(m)
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/marker.ex test/lightweight_charts/marker_test.exs lib/lightweight_charts/encoder.ex
git commit -m "feat: add Marker struct for series markers"
```

---

### Task 11: Chart Struct & Builder API

The top-level struct that composes all the others.

**Files:**
- Create: `lib/lightweight_charts/chart.ex`
- Create: `test/lightweight_charts/chart_test.exs`

**Step 1: Write the failing tests**

```elixir
defmodule LightweightCharts.ChartTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Chart
  alias LightweightCharts.Series
  alias LightweightCharts.Encoder

  describe "new/0" do
    test "creates empty chart" do
      chart = Chart.new()
      assert chart.series == []
      assert chart.events == []
      assert chart.layout == nil
    end
  end

  describe "builder functions" do
    test "layout/2 sets layout options" do
      chart = Chart.new() |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      assert chart.layout.background_color == "#1a1a2e"
      assert chart.layout.text_color == "#e0e0e0"
    end

    test "grid/2 sets grid options" do
      chart = Chart.new() |> Chart.grid(vert_lines_visible: false)
      assert chart.grid.vert_lines_visible == false
    end

    test "crosshair/2 sets crosshair options" do
      chart = Chart.new() |> Chart.crosshair(mode: :magnet)
      assert chart.crosshair.mode == :magnet
    end

    test "time_scale/2 sets time scale options" do
      chart = Chart.new() |> Chart.time_scale(time_visible: true, bar_spacing: 10)
      assert chart.time_scale.time_visible == true
    end

    test "right_price_scale/2 sets right price scale" do
      chart = Chart.new() |> Chart.right_price_scale(visible: true, mode: :logarithmic)
      assert chart.right_price_scale.visible == true
      assert chart.right_price_scale.mode == :logarithmic
    end

    test "left_price_scale/2 sets left price scale" do
      chart = Chart.new() |> Chart.left_price_scale(visible: true)
      assert chart.left_price_scale.visible == true
    end

    test "add_series/2 appends a series" do
      chart =
        Chart.new()
        |> Chart.add_series(Series.candlestick(id: "candles"))
        |> Chart.add_series(Series.line(id: "sma"))

      assert length(chart.series) == 2
      assert Enum.at(chart.series, 0).id == "candles"
      assert Enum.at(chart.series, 1).id == "sma"
    end

    test "on/2 subscribes to events" do
      chart = Chart.new() |> Chart.on(:click) |> Chart.on(:crosshair_move)
      assert :click in chart.events
      assert :crosshair_move in chart.events
    end
  end

  describe "pipeline composition" do
    test "full pipeline builds a complete chart config" do
      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> Chart.grid(vert_lines_visible: false)
        |> Chart.crosshair(mode: :magnet)
        |> Chart.time_scale(time_visible: true)
        |> Chart.add_series(
          Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
        )
        |> Chart.add_series(
          Series.line(id: "sma", color: "#2196f3", line_width: 2)
        )
        |> Chart.on(:click)

      assert chart.layout.background_color == "#1a1a2e"
      assert chart.crosshair.mode == :magnet
      assert length(chart.series) == 2
      assert :click in chart.events
    end
  end

  describe "to_json/1" do
    test "encodes full chart to JSON-compatible map" do
      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e")
        |> Chart.crosshair(mode: :magnet)
        |> Chart.add_series(Series.candlestick(id: "candles", up_color: "#26a69a"))
        |> Chart.on(:click)

      json = Chart.to_json(chart)

      assert json["layout"]["background"]["color"] == "#1a1a2e"
      assert json["crosshair"]["mode"] == 1
      assert length(json["series"]) == 1
      assert hd(json["series"])["type"] == "Candlestick"
      assert "click" in json["events"]
    end

    test "omits nil top-level options" do
      chart = Chart.new() |> Chart.add_series(Series.line(id: "test"))
      json = Chart.to_json(chart)

      refute Map.has_key?(json, "layout")
      refute Map.has_key?(json, "grid")
      assert Map.has_key?(json, "series")
    end
  end
end
```

**Step 2: Run tests — expect failure**

**Step 3: Implement Chart**

Create `lib/lightweight_charts/chart.ex`:

```elixir
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
    |> maybe_put("layout", chart.layout && Encoder.encode(chart.layout))
    |> maybe_put("grid", chart.grid && Encoder.encode(chart.grid))
    |> maybe_put("crosshair", chart.crosshair && Encoder.encode(chart.crosshair))
    |> maybe_put("timeScale", chart.time_scale && Encoder.encode(chart.time_scale))
    |> maybe_put("rightPriceScale", chart.right_price_scale && Encoder.encode(chart.right_price_scale))
    |> maybe_put("leftPriceScale", chart.left_price_scale && Encoder.encode(chart.left_price_scale))
    |> maybe_put("autoSize", chart.auto_size)
    |> maybe_put("width", chart.width)
    |> maybe_put("height", chart.height)
    |> Map.put("series", Enum.map(chart.series, &Encoder.encode/1))
    |> Map.put("events", Enum.map(chart.events, &Map.fetch!(@event_names, &1)))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/chart.ex test/lightweight_charts/chart_test.exs
git commit -m "feat: add Chart struct with full builder API"
```

---

### Task 12: Jason Protocol Implementations

Make all structs JSON-encodable via Jason so they work with `push_event`.

**Files:**
- Create: `lib/lightweight_charts/jason_encoders.ex`
- Create: `test/lightweight_charts/jason_encoding_test.exs`

**Step 1: Write the failing test**

```elixir
defmodule LightweightCharts.JasonEncodingTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.{Chart, Series}

  test "Chart.to_json output is JSON-encodable via Jason" do
    chart =
      Chart.new()
      |> Chart.layout(background_color: "#1a1a2e")
      |> Chart.add_series(Series.candlestick(id: "candles", up_color: "#26a69a"))

    json_map = Chart.to_json(chart)
    assert {:ok, json_string} = Jason.encode(json_map)
    assert is_binary(json_string)

    decoded = Jason.decode!(json_string)
    assert decoded["layout"]["background"]["color"] == "#1a1a2e"
    assert hd(decoded["series"])["type"] == "Candlestick"
  end
end
```

**Step 2: Run test — expect pass** (since `Chart.to_json/1` returns plain maps/lists/strings/numbers)

If it passes already, no implementation needed. The `to_json` functions intentionally return JSON-compatible primitives. If any struct leaks through, add the appropriate `to_map` call.

**Step 3: Commit**

```bash
git add test/lightweight_charts/jason_encoding_test.exs
git commit -m "test: verify full chart config is Jason-encodable"
```

---

### Task 13: Vendor the lightweight-charts JS Library

Build the JS library and copy the production bundle into the package.

**Files:**
- Create: `assets/vendor/lightweight-charts.mjs`

**Step 1: Install JS dependencies and build**

```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight-charts
npm install
npm run build:prod
```

**Step 2: Verify the build produced output**

```bash
ls -la dist/lightweight-charts.production.mjs
```

Expected: File exists, ~200-300KB

**Step 3: Copy the production build to the package**

```bash
mkdir -p /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts/assets/vendor
cp /Users/james/Desktop/lib/lightweight-charts-ex/lightweight-charts/dist/lightweight-charts.production.mjs \
   /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts/assets/vendor/lightweight-charts.mjs
```

**Step 4: Commit**

```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts
git add assets/vendor/lightweight-charts.mjs
git commit -m "feat: vendor lightweight-charts v5.1.0 production build"
```

---

### Task 14: JavaScript Hook

The core JS hook that bridges LiveView events to lightweight-charts.

**Files:**
- Create: `assets/js/hooks/lightweight_charts.js`

**Step 1: Create the hook**

Create `assets/js/hooks/lightweight_charts.js`:

```javascript
import {
  createChart,
  LineSeries,
  AreaSeries,
  BarSeries,
  CandlestickSeries,
  HistogramSeries,
  BaselineSeries,
  createSeriesMarkers,
} from "../../vendor/lightweight-charts.mjs";

const SERIES_DEFS = {
  Line: LineSeries,
  Area: AreaSeries,
  Bar: BarSeries,
  Candlestick: CandlestickSeries,
  Histogram: HistogramSeries,
  Baseline: BaselineSeries,
};

const EVENT_MAP = {
  click: "subscribeClick",
  dblClick: "subscribeDblClick",
  crosshairMove: "subscribeCrosshairMove",
};

export const LightweightChartsHook = {
  mounted() {
    const config = JSON.parse(this.el.dataset.config);
    this._initChart(config);
  },

  destroyed() {
    this._cleanup();
  },

  _initChart(config) {
    const { series: seriesConfigs, events, ...chartOptions } = config;

    this._chart = createChart(this.el, chartOptions);
    this._series = {};
    this._markers = {};
    this._subscriptions = [];

    // Create series
    for (const sc of seriesConfigs) {
      const def = SERIES_DEFS[sc.type];
      if (!def) {
        console.warn(`[LightweightCharts] Unknown series type: ${sc.type}`);
        continue;
      }
      const series = this._chart.addSeries(def, sc.options || {}, sc.paneIndex);
      this._series[sc.id] = series;
    }

    // Set up ResizeObserver
    this._resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const { width, height } = entry.contentRect;
        if (width > 0 && height > 0) {
          this._chart.resize(width, height);
        }
      }
    });
    this._resizeObserver.observe(this.el);

    // Subscribe to chart events
    if (events) {
      for (const event of events) {
        this._subscribeEvent(event);
      }
    }

    // Listen for server-pushed events
    const id = this.el.id;

    this.handleEvent(`lc:${id}:set_data`, ({ series_id, data }) => {
      const s = this._series[series_id];
      if (s) s.setData(data);
    });

    this.handleEvent(`lc:${id}:update`, ({ series_id, point }) => {
      const s = this._series[series_id];
      if (s) s.update(point);
    });

    this.handleEvent(`lc:${id}:apply_options`, ({ target, options }) => {
      if (target === "chart") {
        this._chart.applyOptions(options);
      } else {
        const s = this._series[target];
        if (s) s.applyOptions(options);
      }
    });

    this.handleEvent(`lc:${id}:fit_content`, () => {
      this._chart.timeScale().fitContent();
    });

    this.handleEvent(`lc:${id}:set_visible_range`, ({ from, to }) => {
      this._chart.timeScale().setVisibleRange({ from, to });
    });

    this.handleEvent(`lc:${id}:set_markers`, ({ series_id, markers }) => {
      const s = this._series[series_id];
      if (!s) return;

      // Clean up existing markers for this series
      if (this._markers[series_id]) {
        this._markers[series_id].detach();
      }

      if (markers && markers.length > 0) {
        this._markers[series_id] = createSeriesMarkers(s, markers);
      }
    });
  },

  _subscribeEvent(event) {
    const methodName = EVENT_MAP[event];
    if (!methodName) {
      // Handle time scale events separately
      if (event === "visibleTimeRangeChange") {
        const handler = (range) => {
          this.pushEvent("lc:visible_range_change", {
            from: range?.from,
            to: range?.to,
          });
        };
        this._chart.timeScale().subscribeVisibleTimeRangeChange(handler);
        this._subscriptions.push(() =>
          this._chart.timeScale().unsubscribeVisibleTimeRangeChange(handler)
        );
      }
      return;
    }

    const handler = (param) => {
      const payload = {
        time: param.time,
        logical: param.logical,
        point: param.point,
        pane_index: param.paneIndex,
      };

      if (param.seriesData) {
        const seriesData = {};
        for (const [seriesId, data] of Object.entries(this._series)) {
          const val = param.seriesData.get(this._series[seriesId]);
          if (val) seriesData[seriesId] = val;
        }
        payload.series_data = seriesData;
      }

      if (param.hoveredSeries) {
        for (const [id, s] of Object.entries(this._series)) {
          if (s === param.hoveredSeries) {
            payload.hovered_series = id;
            break;
          }
        }
      }

      const eventName = event === "click" ? "lc:click" :
                         event === "dblClick" ? "lc:dbl_click" :
                         "lc:crosshair_move";

      this.pushEvent(eventName, payload);
    };

    this._chart[methodName](handler);
    const unsubMethod = methodName.replace("subscribe", "unsubscribe");
    this._subscriptions.push(() => this._chart[unsubMethod](handler));
  },

  _cleanup() {
    for (const unsub of this._subscriptions || []) {
      try { unsub(); } catch (_) {}
    }

    for (const [, markerApi] of Object.entries(this._markers || {})) {
      try { markerApi.detach(); } catch (_) {}
    }

    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
    }

    if (this._chart) {
      this._chart.remove();
    }

    this._chart = null;
    this._series = {};
    this._markers = {};
    this._subscriptions = [];
  },
};
```

**Step 2: Verify the file is syntactically valid**

```bash
node -c /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts/assets/js/hooks/lightweight_charts.js
```

Expected: No syntax errors

**Step 3: Commit**

```bash
git add assets/js/hooks/lightweight_charts.js
git commit -m "feat: add LiveView JS hook for lightweight-charts"
```

---

### Task 15: LiveView Function Component

**Files:**
- Create: `lib/lightweight_charts/live/chart_component.ex`
- Create: `test/lightweight_charts/live/chart_component_test.exs`

**Step 1: Write the failing test**

```elixir
defmodule LightweightCharts.Live.ChartComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias LightweightCharts.{Chart, Series}

  test "renders chart container with correct attributes" do
    chart = Chart.new() |> Chart.add_series(Series.line(id: "test"))

    assigns = %{chart: chart}

    html =
      rendered_to_string(~H"""
      <LightweightCharts.Live.ChartComponent.chart id="my-chart" chart={@chart} class="h-96" />
      """)

    assert html =~ ~s(id="my-chart")
    assert html =~ ~s(phx-hook="LightweightCharts")
    assert html =~ ~s(phx-update="ignore")
    assert html =~ ~s(data-config=)
    assert html =~ ~s(class="h-96")
  end

  test "data-config contains valid JSON with series" do
    chart = Chart.new() |> Chart.add_series(Series.candlestick(id: "candles", up_color: "#26a69a"))

    assigns = %{chart: chart}

    html =
      rendered_to_string(~H"""
      <LightweightCharts.Live.ChartComponent.chart id="test-chart" chart={@chart} />
      """)

    # Extract data-config value
    [_, config_json] = Regex.run(~r/data-config="([^"]*)"/, html)
    config = config_json |> Phoenix.HTML.safe_to_string() |> Jason.decode!()

    assert length(config["series"]) == 1
    assert hd(config["series"])["type"] == "Candlestick"
  end
end
```

Note: This test depends on `phoenix_live_view` being available. The test may need adjustments based on exact Phoenix.LiveViewTest API.

**Step 2: Run test — expect failure**

**Step 3: Implement ChartComponent**

Create `lib/lightweight_charts/live/chart_component.ex`:

```elixir
defmodule LightweightCharts.Live.ChartComponent do
  @moduledoc """
  Phoenix function component for rendering a lightweight chart.

  ## Usage

      <LightweightCharts.Live.ChartComponent.chart
        id="price-chart"
        chart={@chart_config}
        class="h-96 w-full"
      />

  The component renders a `div` with the `LightweightCharts` hook attached.
  Chart configuration is passed via a `data-config` attribute as JSON.

  Use `phx-update="ignore"` to prevent LiveView from patching the chart DOM.
  Data updates are handled via server-pushed events, not DOM diffing.
  """

  use Phoenix.Component

  alias LightweightCharts.Chart

  attr :id, :string, required: true, doc: "Unique DOM ID for the chart container"
  attr :chart, Chart, required: true, doc: "Chart configuration struct"
  attr :class, :string, default: nil, doc: "CSS class(es) for the container div"
  attr :style, :string, default: nil, doc: "Inline CSS styles for the container div"
  attr :rest, :global, doc: "Additional HTML attributes"

  @doc "Renders a lightweight chart container."
  def chart(assigns) do
    config_json = assigns.chart |> Chart.to_json() |> Jason.encode!()
    assigns = assign(assigns, :config_json, config_json)

    ~H"""
    <div
      id={@id}
      phx-hook="LightweightCharts"
      phx-update="ignore"
      data-config={@config_json}
      class={@class}
      style={@style}
      {@rest}
    />
    """
  end
end
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/live/chart_component.ex test/lightweight_charts/live/chart_component_test.exs
git commit -m "feat: add LiveView function component for chart rendering"
```

---

### Task 16: LiveView Helpers (push_data, push_update, etc.)

**Files:**
- Create: `lib/lightweight_charts/live/helpers.ex`
- Create: `test/lightweight_charts/live/helpers_test.exs`

**Step 1: Write the failing test**

```elixir
defmodule LightweightCharts.Live.HelpersTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Live.Helpers

  describe "event name generation" do
    test "push_data builds correct event name" do
      assert Helpers.event_name("my-chart", :set_data) == "lc:my-chart:set_data"
    end

    test "push_update builds correct event name" do
      assert Helpers.event_name("my-chart", :update) == "lc:my-chart:update"
    end
  end

  describe "encode_data_points/1" do
    test "converts DateTime times in data points" do
      data = [
        %{time: ~U[2024-01-15 00:00:00Z], value: 42.5},
        %{time: ~U[2024-01-16 00:00:00Z], value: 43.1}
      ]

      encoded = Helpers.encode_data_points(data)

      assert hd(encoded)["time"] == 1705276800
      assert hd(encoded)["value"] == 42.5
    end

    test "converts Date times to strings" do
      data = [%{time: ~D[2024-01-15], open: 100, high: 105, low: 99, close: 103}]
      encoded = Helpers.encode_data_points(data)

      assert hd(encoded)["time"] == "2024-01-15"
      assert hd(encoded)["open"] == 100
    end

    test "passes through integer timestamps" do
      data = [%{time: 1705276800, value: 42.5}]
      encoded = Helpers.encode_data_points(data)
      assert hd(encoded)["time"] == 1705276800
    end
  end
end
```

**Step 2: Run tests — expect failure**

**Step 3: Implement Helpers**

Create `lib/lightweight_charts/live/helpers.ex`:

```elixir
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
```

**Step 4: Run tests — expect pass**

**Step 5: Commit**

```bash
git add lib/lightweight_charts/live/helpers.ex test/lightweight_charts/live/helpers_test.exs
git commit -m "feat: add LiveView helpers for pushing data and commands"
```

---

### Task 17: Main Module Delegates

Wire up the main `LightweightCharts` module as the public API facade.

**Files:**
- Modify: `lib/lightweight_charts.ex`

**Step 1: Write the failing test**

Add to `test/lightweight_charts_test.exs`:

```elixir
defmodule LightweightChartsTest do
  use ExUnit.Case, async: true

  test "top-level module exposes chart/0 function component" do
    assert function_exported?(LightweightCharts, :chart, 1)
  end
end
```

**Step 2: Update the main module**

Replace `lib/lightweight_charts.ex`:

```elixir
defmodule LightweightCharts do
  @moduledoc """
  TradingView Lightweight Charts for Phoenix LiveView.

  Provides declarative chart configuration via Elixir structs and a
  bundled JavaScript hook for rendering interactive financial charts.

  ## Quick Start

  ### 1. Build your chart configuration

      alias LightweightCharts.{Chart, Series}

      chart =
        Chart.new()
        |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
        |> Chart.crosshair(mode: :magnet)
        |> Chart.time_scale(time_visible: true)
        |> Chart.add_series(
          Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
        )
        |> Chart.on(:click)

  ### 2. Render in your LiveView template

      <LightweightCharts.chart id="price-chart" chart={@chart} class="h-96 w-full" />

  ### 3. Push data from your LiveView

      LightweightCharts.push_data(socket, "price-chart", "candles", candle_data)
      LightweightCharts.push_update(socket, "price-chart", "candles", new_candle)

  ### 4. Handle interaction events

      def handle_event("lc:click", %{"time" => time}, socket) do
        # User clicked a point on the chart
        {:noreply, socket}
      end

  ## JavaScript Setup

  In your `app.js`:

      import { LightweightChartsHook } from "lightweight_charts"

      let liveSocket = new LiveSocket("/live", Socket, {
        hooks: { LightweightCharts: LightweightChartsHook }
      })
  """

  use Phoenix.Component

  alias LightweightCharts.{Chart, Live.Helpers}

  # Re-export the function component
  attr :id, :string, required: true
  attr :chart, Chart, required: true
  attr :class, :string, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  @doc "Renders a lightweight chart. See `LightweightCharts.Live.ChartComponent.chart/1`."
  defdelegate chart(assigns), to: LightweightCharts.Live.ChartComponent

  # Re-export helpers
  defdelegate push_data(socket, chart_id, series_id, data), to: Helpers
  defdelegate push_update(socket, chart_id, series_id, point), to: Helpers
  defdelegate push_options(socket, chart_id, target, options), to: Helpers
  defdelegate fit_content(socket, chart_id), to: Helpers
  defdelegate set_visible_range(socket, chart_id, from, to), to: Helpers
  defdelegate set_markers(socket, chart_id, series_id, markers), to: Helpers
end
```

**Step 3: Run full test suite**

Run: `mix test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/lightweight_charts.ex test/lightweight_charts_test.exs
git commit -m "feat: wire up main module as public API facade"
```

---

### Task 18: JS Hook Entry Point & Package Export

Create the package entry point so users can `import { LightweightChartsHook } from "lightweight_charts"`.

**Files:**
- Create: `assets/js/index.js`
- Create: `package.json` (in project root, for npm resolution)

**Step 1: Create the JS entry point**

Create `assets/js/index.js`:

```javascript
export { LightweightChartsHook } from "./hooks/lightweight_charts.js";
```

**Step 2: Create package.json for npm resolution**

Create `package.json` in the lightweight_charts project root (not the lightweight-charts library):

```json
{
  "name": "lightweight_charts",
  "version": "0.1.0",
  "private": true,
  "main": "./assets/js/index.js",
  "module": "./assets/js/index.js",
  "exports": {
    ".": "./assets/js/index.js",
    "./hooks": "./assets/js/hooks/lightweight_charts.js"
  }
}
```

This allows Phoenix projects to import via the dependency path resolution:

```javascript
// In the user's app.js:
import { LightweightChartsHook } from "../deps/lightweight_charts"
```

Or if they configure their esbuild/bundler to resolve the package name.

**Step 3: Commit**

```bash
git add assets/js/index.js package.json
git commit -m "feat: add JS entry point for hook import"
```

---

### Task 19: README

**Files:**
- Create: `README.md`

**Step 1: Write the README**

Create `README.md`:

```markdown
# LightweightCharts

[![Hex.pm](https://img.shields.io/hexpm/v/lightweight_charts.svg)](https://hex.pm/packages/lightweight_charts)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/lightweight_charts)

TradingView [Lightweight Charts](https://www.tradingview.com/lightweight-charts/) for Phoenix LiveView.

Build interactive financial charts with declarative Elixir configuration and real-time data streaming.

## Features

- **6 series types** — Line, Area, Bar, Candlestick, Histogram, Baseline
- **Declarative configuration** — Typed Elixir structs with pipeline-friendly builder API
- **Real-time updates** — Stream data points via `push_event`, no page reload
- **Bidirectional events** — Receive clicks, crosshair moves, and range changes in your LiveView
- **Responsive** — Auto-resizes via ResizeObserver
- **Zero JS config** — Drop-in function component with bundled hook

## Installation

Add to your `mix.exs`:

    def deps do
      [
        {:lightweight_charts, "~> 0.1.0"}
      ]
    end

Then add the JavaScript hook in your `assets/js/app.js`:

    import { LightweightChartsHook } from "../../deps/lightweight_charts"

    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { LightweightCharts: LightweightChartsHook }
    })

## Quick Start

### 1. Build chart configuration

    alias LightweightCharts.{Chart, Series}

    chart =
      Chart.new()
      |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      |> Chart.crosshair(mode: :magnet)
      |> Chart.time_scale(time_visible: true)
      |> Chart.add_series(
        Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      )

### 2. Render in your LiveView

    # In mount:
    {:ok, assign(socket, chart: chart)}

    # In template:
    <LightweightCharts.chart id="price-chart" chart={@chart} class="h-96 w-full" />

### 3. Push data

    # Full dataset
    LightweightCharts.push_data(socket, "price-chart", "candles", candle_data)

    # Stream a single point
    LightweightCharts.push_update(socket, "price-chart", "candles", new_candle)

### 4. Handle events

Enable events in config:

    chart = Chart.new() |> Chart.on(:click) |> Chart.on(:crosshair_move)

Handle in your LiveView:

    def handle_event("lc:click", %{"time" => time, "series_data" => data}, socket) do
      # User clicked a point on the chart
      {:noreply, socket}
    end

## Data Formats

OHLC data (Candlestick, Bar):

    [
      %{time: ~U[2024-01-15 00:00:00Z], open: 185.0, high: 187.5, low: 184.2, close: 186.8},
      %{time: ~D[2024-01-16], open: 186.8, high: 189.0, low: 186.0, close: 188.5}
    ]

Single-value data (Line, Area, Histogram, Baseline):

    [
      %{time: ~U[2024-01-15 00:00:00Z], value: 42.5},
      %{time: 1705363200, value: 43.1}
    ]

Time values accept `DateTime`, `NaiveDateTime`, `Date`, Unix timestamps (integer), or `"YYYY-MM-DD"` strings.

## Series Types

| Type | Constructor | Data Fields |
|------|-------------|-------------|
| Candlestick | `Series.candlestick/1` | time, open, high, low, close |
| Line | `Series.line/1` | time, value |
| Area | `Series.area/1` | time, value |
| Bar | `Series.bar/1` | time, open, high, low, close |
| Histogram | `Series.histogram/1` | time, value |
| Baseline | `Series.baseline/1` | time, value |

## License

Apache-2.0. Includes TradingView Lightweight Charts, also Apache-2.0.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage guide"
```

---

### Task 20: Demo Phoenix App

Create a minimal Phoenix LiveView app demonstrating the package.

**Files:**
- Create: `examples/demo/` (Phoenix app scaffold)

**Step 1: Generate the Phoenix app**

```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts
mkdir -p examples
cd examples
mix phx.new demo --no-ecto --no-mailer --no-dashboard --no-gettext
```

**Step 2: Add lightweight_charts as a path dependency**

Edit `examples/demo/mix.exs` to add:

```elixir
{:lightweight_charts, path: "../.."}
```

**Step 3: Add the JS hook import**

Edit `examples/demo/assets/js/app.js` to add:

```javascript
import { LightweightChartsHook } from "../../../"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

**Step 4: Create a chart LiveView**

Create `examples/demo/lib/demo_web/live/chart_live.ex`:

```elixir
defmodule DemoWeb.ChartLive do
  use DemoWeb, :live_view

  alias LightweightCharts.{Chart, Series}

  @impl true
  def mount(_params, _session, socket) do
    chart =
      Chart.new()
      |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      |> Chart.crosshair(mode: :magnet)
      |> Chart.time_scale(time_visible: true)
      |> Chart.add_series(
        Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      )
      |> Chart.add_series(
        Series.histogram(id: "volume", color: "rgba(38,166,154,0.5)", pane_index: 1)
      )
      |> Chart.on(:click)

    socket = assign(socket, chart: chart)

    if connected?(socket) do
      Process.send_after(self(), :load_data, 100)
      Process.send_after(self(), :stream_tick, 2000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_data, socket) do
    {candles, volumes} = generate_sample_data(100)

    socket =
      socket
      |> LightweightCharts.push_data("price-chart", "candles", candles)
      |> LightweightCharts.push_data("price-chart", "volume", volumes)
      |> LightweightCharts.fit_content("price-chart")

    {:noreply, socket}
  end

  def handle_info(:stream_tick, socket) do
    candle = generate_random_candle()
    volume = %{time: candle.time, value: :rand.uniform(1000) * 100}

    socket =
      socket
      |> LightweightCharts.push_update("price-chart", "candles", candle)
      |> LightweightCharts.push_update("price-chart", "volume", volume)

    Process.send_after(self(), :stream_tick, 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_event("lc:click", params, socket) do
    IO.inspect(params, label: "Chart click")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4 text-white">LightweightCharts Demo</h1>
      <LightweightCharts.chart id="price-chart" chart={@chart} class="h-[600px] w-full" />
    </div>
    """
  end

  defp generate_sample_data(count) do
    base_time = DateTime.utc_now() |> DateTime.add(-count * 86400, :second)
    base_price = 100.0

    {candles, _} =
      Enum.map_reduce(1..count, base_price, fn i, prev_close ->
        time = DateTime.add(base_time, i * 86400, :second)
        open = prev_close + (:rand.uniform() - 0.5) * 2
        close = open + (:rand.uniform() - 0.5) * 4
        high = max(open, close) + :rand.uniform() * 2
        low = min(open, close) - :rand.uniform() * 2

        candle = %{time: time, open: open, high: high, low: low, close: close}
        {candle, close}
      end)

    volumes =
      Enum.map(candles, fn c ->
        %{time: c.time, value: :rand.uniform(1000) * 100}
      end)

    {candles, volumes}
  end

  defp generate_random_candle do
    time = DateTime.utc_now()
    open = 100 + :rand.uniform() * 50
    close = open + (:rand.uniform() - 0.5) * 4
    high = max(open, close) + :rand.uniform() * 2
    low = min(open, close) - :rand.uniform() * 2

    %{time: time, open: open, high: high, low: close, close: close}
  end
end
```

**Step 5: Add the route**

Edit `examples/demo/lib/demo_web/router.ex` — add inside the `"/"` scope:

```elixir
live "/", ChartLive
```

**Step 6: Install deps and verify it compiles**

```bash
cd examples/demo
mix deps.get
mix compile
```

**Step 7: Commit**

```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts
git add examples/
git commit -m "feat: add demo Phoenix app with live candlestick chart"
```

---

### Task 21: Final Integration Test

Run the full test suite and verify everything works together.

**Step 1: Run all tests**

```bash
cd /Users/james/Desktop/lib/lightweight-charts-ex/lightweight_charts
mix test
```

Expected: All tests pass

**Step 2: Generate docs and verify**

```bash
mix docs
open doc/index.html
```

Verify: All modules documented, no warnings, module grouping correct.

**Step 3: Check formatting**

```bash
mix format --check-formatted
```

If failures, run `mix format` and commit.

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: format code and verify full test suite"
```

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | Project scaffolding | mix.exs, lib/, test/ |
| 2 | Encoder (snake→camelCase, time, enums) | encoder.ex |
| 3 | Layout struct | layout.ex |
| 4 | Grid struct | grid.ex |
| 5 | Crosshair struct | crosshair.ex |
| 6 | TimeScale struct | time_scale.ex |
| 7 | PriceScale struct | price_scale.ex |
| 8 | Series struct (all 6 types) | series.ex |
| 9 | PriceLine struct | price_line.ex |
| 10 | Marker struct | marker.ex |
| 11 | Chart struct & builder API | chart.ex |
| 12 | Jason encoding verification | jason_encoding_test.exs |
| 13 | Vendor lightweight-charts JS | assets/vendor/ |
| 14 | JavaScript hook | assets/js/hooks/ |
| 15 | LiveView function component | live/chart_component.ex |
| 16 | LiveView helpers | live/helpers.ex |
| 17 | Main module facade | lightweight_charts.ex |
| 18 | JS entry point & package.json | assets/js/index.js |
| 19 | README | README.md |
| 20 | Demo Phoenix app | examples/demo/ |
| 21 | Final integration test | — |
