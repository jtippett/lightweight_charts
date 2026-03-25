# LightweightCharts

[![Hex.pm](https://img.shields.io/hexpm/v/lightweight_charts.svg)](https://hex.pm/packages/lightweight_charts)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/lightweight_charts)
[![License](https://img.shields.io/hexpm/l/lightweight_charts.svg)](https://github.com/user/lightweight_charts/blob/main/LICENSE)

TradingView [Lightweight Charts](https://www.tradingview.com/lightweight-charts/) for Phoenix LiveView.

Build interactive financial charts with declarative Elixir configuration and real-time data streaming.

## Features

- **6 series types** -- Candlestick, Line, Area, Bar, Histogram, Baseline
- **Declarative configuration** -- Typed Elixir structs with a pipeline-friendly builder API
- **Real-time updates** -- Stream data points to the browser via `push_event`, no page reload
- **Bidirectional events** -- Receive clicks, crosshair moves, and visible range changes in your LiveView
- **Markers** -- Place visual annotations (arrows, circles, squares) on data points
- **Multi-pane layouts** -- Display series in separate panes with independent price scales
- **Responsive** -- Auto-resizes via `ResizeObserver`
- **Zero JS config** -- Drop-in function component with a bundled hook

## Installation

Add `lightweight_charts` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lightweight_charts, "~> 0.1.0"}
  ]
end
```

Then add the JavaScript hook to your `assets/js/app.js`.

### With esbuild (default Phoenix bundler)

```javascript
import { LightweightChartsHook } from "../../deps/lightweight_charts"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

The import path `../../deps/lightweight_charts` resolves from `assets/js/` to the
package's entry point at `deps/lightweight_charts/assets/js/index.js`. esbuild
follows this path and bundles the hook along with the vendored lightweight-charts
library automatically.

### With bun

```javascript
import { LightweightChartsHook } from "../../deps/lightweight_charts"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

Bun resolves the same relative import path. If you prefer, you can configure a
path alias in your `bunfig.toml` or bundler config to use a shorter import like
`"lightweight_charts"`.

## Quick Start

### 1. Build chart configuration

```elixir
alias LightweightCharts.{Chart, Series}

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
```

Configuration is built entirely with Elixir structs -- no maps, no raw JSON.
The pipeline API lets you compose options incrementally and the result is a
plain `%Chart{}` struct you can inspect, store, or pass around.

### 2. Render in your LiveView

In your `mount/3`:

```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket, chart: chart)}
end
```

In your template (HEEx):

```heex
<LightweightCharts.chart id="price-chart" chart={@chart} class="h-96 w-full" />
```

The component renders a `div` with the `LightweightCharts` hook attached and
the chart configuration serialized as a `data-config` attribute. The hook
reads the config on mount and creates the chart.

### 3. Push data

Send a full dataset to replace all series data:

```elixir
LightweightCharts.push_data(socket, "price-chart", "candles", candle_data)
```

Stream a single data point (appends or updates the last bar):

```elixir
LightweightCharts.push_update(socket, "price-chart", "candles", new_candle)
```

### 4. Handle events

Subscribe to events in your chart config:

```elixir
chart =
  Chart.new()
  |> Chart.on(:click)
  |> Chart.on(:crosshair_move)
  |> Chart.on(:visible_range_change)
```

Then handle them in your LiveView:

```elixir
def handle_event("lc:click", %{"time" => time, "series_data" => data}, socket) do
  # User clicked a point on the chart
  {:noreply, socket}
end

def handle_event("lc:crosshairMove", %{"time" => time, "series_data" => data}, socket) do
  # Crosshair moved
  {:noreply, socket}
end
```

### 5. Additional helpers

```elixir
# Update chart or series options at runtime
LightweightCharts.push_options(socket, "price-chart", "chart", %{layout: %{background_color: "#000"}})

# Auto-fit all data into the visible area
LightweightCharts.fit_content(socket, "price-chart")

# Set the visible time range
LightweightCharts.set_visible_range(socket, "price-chart", ~U[2024-01-01 00:00:00Z], ~U[2024-06-01 00:00:00Z])

# Add markers to a series
alias LightweightCharts.Marker

markers = [
  Marker.new(time: ~U[2024-01-15 00:00:00Z], position: :above_bar, shape: :arrow_down, color: "#ef5350", text: "Sell"),
  Marker.new(time: ~U[2024-02-01 00:00:00Z], position: :below_bar, shape: :arrow_up, color: "#26a69a", text: "Buy")
]

LightweightCharts.set_markers(socket, "price-chart", "candles", markers)
```

## Data Formats

### OHLC data (Candlestick, Bar)

```elixir
[
  %{time: ~U[2024-01-15 00:00:00Z], open: 185.0, high: 187.5, low: 184.2, close: 186.8},
  %{time: ~D[2024-01-16], open: 186.8, high: 189.0, low: 186.0, close: 188.5}
]
```

### Single-value data (Line, Area, Histogram, Baseline)

```elixir
[
  %{time: ~U[2024-01-15 00:00:00Z], value: 42.5},
  %{time: 1705363200, value: 43.1}
]
```

### Time format flexibility

Time values accept any of the following formats -- you can even mix them within the same dataset:

| Format | Example | Encoding |
|--------|---------|----------|
| `DateTime` | `~U[2024-01-15 00:00:00Z]` | Unix timestamp (integer) |
| `NaiveDateTime` | `~N[2024-01-15 00:00:00]` | Unix timestamp (integer, assumes UTC) |
| `Date` | `~D[2024-01-15]` | `"2024-01-15"` string |
| Unix timestamp | `1705276800` | Passed through |
| String | `"2024-01-15"` | Passed through |

## Series Types

| Type | Constructor | Data Fields |
|------|-------------|-------------|
| Candlestick | `Series.candlestick/1` | time, open, high, low, close |
| Line | `Series.line/1` | time, value |
| Area | `Series.area/1` | time, value |
| Bar | `Series.bar/1` | time, open, high, low, close |
| Histogram | `Series.histogram/1` | time, value |
| Baseline | `Series.baseline/1` | time, value |

Each constructor accepts keyword options for styling. For example:

```elixir
Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
Series.line(id: "sma", color: "#2196f3", line_width: 2)
Series.histogram(id: "volume", color: "#26a69a", pane_index: 1)
Series.baseline(id: "delta", base_value: 0, top_line_color: "#26a69a", bottom_line_color: "#ef5350")
```

## Events

| Event | Atom | LiveView event name |
|-------|------|---------------------|
| Click | `:click` | `"lc:click"` |
| Double click | `:dbl_click` | `"lc:dblClick"` |
| Crosshair move | `:crosshair_move` | `"lc:crosshairMove"` |
| Visible range change | `:visible_range_change` | `"lc:visibleTimeRangeChange"` |

## Chart Configuration Reference

The `Chart` builder supports these configuration sections:

```elixir
Chart.new()
|> Chart.layout(background_color: "#fff", text_color: "#333", font_size: 12, font_family: "Arial")
|> Chart.grid(vert_lines_visible: false, horz_lines_color: "#eee")
|> Chart.crosshair(mode: :normal)
|> Chart.time_scale(time_visible: true, bar_spacing: 6, right_offset: 5)
|> Chart.right_price_scale(visible: true, border_visible: false)
|> Chart.left_price_scale(visible: false)
|> Chart.add_series(series)
|> Chart.on(:click)
```

## License

This package is licensed under [Apache-2.0](LICENSE).

This package includes [TradingView Lightweight Charts](https://github.com/tradingview/lightweight-charts)
v5.1.0, which is also licensed under Apache-2.0. Copyright TradingView, Inc.
