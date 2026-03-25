# lightweight_charts — Design Document

Package: `lightweight_charts`
Module: `LightweightCharts`
Date: 2026-03-25

## Purpose

An Elixir package that wraps TradingView's lightweight-charts v5.1.0 for use in Phoenix LiveView applications. Provides declarative chart configuration via typed structs and a bundled JS hook for rendering, real-time updates, and bidirectional interaction events.

## Architecture

Three layers, each usable independently:

### Config Layer (pure Elixir, no Phoenix dependency)

Typed structs and builder functions that produce chart configuration as nested Elixir data. Converts to camelCase JSON for the JS side.

**Core structs:**

- `Chart` — Top-level container. Layout, grid, crosshair, time scale, price scale options, and a list of series.
- `Series` — Type (`:line`, `:area`, `:bar`, `:candlestick`, `:histogram`, `:baseline`), type-specific style options, and a string ID for referencing in events.
- `Layout` — Background color, text color, font family/size.
- `Grid` — Vertical/horizontal line visibility, color, style.
- `Crosshair` — Mode (`:normal`, `:magnet`), line styling.
- `TimeScale` — Bar spacing, right offset, visibility, time/seconds visibility.
- `PriceScale` — Position (`:left`, `:right`), mode, border visibility.
- `PriceLine` — Horizontal marker lines on a series.
- `Marker` — Point markers on a series (shape, color, text, position).
- `Encoder` — Converts structs to camelCase JSON maps.

**Builder API:**

```elixir
import LightweightCharts

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
```

All option names are snake_cased Elixir atoms. The encoder handles conversion to camelCase.

### LiveView Layer (depends on Phoenix LiveView)

A function component and helper functions for LiveView integration.

**Component:**

```heex
<LightweightCharts.chart
  id="price-chart"
  chart={@chart_config}
  class="h-96 w-full"
/>
```

Renders a `div` with `phx-hook="LightweightCharts"`, `phx-update="ignore"`, and JSON config in a data attribute.

**Server-to-client helpers:**

```elixir
# Full data set
socket |> LightweightCharts.push_data("price-chart", "candles", candle_data)

# Single point update (streaming)
socket |> LightweightCharts.push_update("price-chart", "candles", new_candle)

# Runtime config changes (e.g., theme switching)
socket |> LightweightCharts.push_options("price-chart", new_options)

# Time scale controls
socket |> LightweightCharts.fit_content("price-chart")
socket |> LightweightCharts.set_visible_range("price-chart", from, to)
```

**Client-to-server events (opt-in via config):**

```elixir
# Enabled via:
Chart.new() |> Chart.on(:click) |> Chart.on(:crosshair_move) |> Chart.on(:visible_range_change)

# Received as:
def handle_event("lc:click", %{"time" => time, "price" => price, ...}, socket)
def handle_event("lc:crosshair_move", %{"time" => time, "series_data" => data}, socket)
def handle_event("lc:visible_range_change", %{"from" => from, "to" => to}, socket)
```

Events are namespaced with `lc:` to avoid collisions.

### JS Layer (bundled hook)

Users import the hook in their `app.js`:

```javascript
import { LightweightChartsHook } from "lightweight_charts/hooks"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

**Hook lifecycle:**

- `mounted()` — Reads JSON config from data attribute, calls `createChart()`, creates series, sets up `ResizeObserver`, subscribes to enabled interaction events.
- `updated()` — No-op (`phx-update="ignore"`).
- `destroyed()` — Calls `chart.remove()`, disconnects observer, cleans up subscriptions.

**Server-to-client events:**

- `lc:${id}:set_data` — `series.setData(data)` for full replacement.
- `lc:${id}:update` — `series.update(bar)` for streaming.
- `lc:${id}:apply_options` — `chart.applyOptions(opts)` or `series.applyOptions(opts)`.
- `lc:${id}:fit_content` — `chart.timeScale().fitContent()`.
- `lc:${id}:set_visible_range` — Sets time scale visible range.

The hook vendors the lightweight-charts library — users don't install it separately.

## Data Structures

**OHLC data (Candlestick/Bar):**

```elixir
%{time: ~U[2024-01-15 00:00:00Z], open: 185.0, high: 187.5, low: 184.2, close: 186.8}
```

**Single-value data (Line/Area/Histogram/Baseline):**

```elixir
%{time: ~U[2024-01-15 00:00:00Z], value: 42.5}
```

**Time formats accepted:**

- `DateTime` / `NaiveDateTime` — converted to Unix timestamp.
- `Date` — converted to `"YYYY-MM-DD"` string (business day format).
- Integer — passed through as Unix timestamp.
- String `"YYYY-MM-DD"` — passed through.

Per-point styling (e.g., `color: "#ff0000"`) is optional and passed through when present.

## Scope

### Included in initial release

- All 6 built-in series types (Line, Area, Bar, Candlestick, Histogram, Baseline).
- Standard time-based chart (`createChart()` only).
- Full chart configuration via structs.
- LiveView function component with automatic hook wiring.
- Bidirectional events (push data, receive interactions).
- Series markers via built-in plugin.
- Responsive sizing via ResizeObserver.
- Comprehensive HexDocs with `@moduledoc`/`@doc` on all public API.
- README with installation, getting-started guide, and examples.
- Demo Phoenix app in `examples/demo/`.

### Deferred to future releases

- Yield curve chart (`createYieldCurveChart()`).
- Options chart (`createOptionsChart()`).
- Custom series plugin API.
- Watermark plugins (text/image).
- Screenshot/export API.
- Non-LiveView integrations (static HTML generation).

## Project Structure

```
lightweight_charts/
├── lib/
│   ├── lightweight_charts.ex           # Main public API module
│   └── lightweight_charts/
│       ├── chart.ex                    # Chart struct & builders
│       ├── series.ex                   # Series struct & type constructors
│       ├── layout.ex                   # Layout options
│       ├── grid.ex                     # Grid options
│       ├── crosshair.ex               # Crosshair options
│       ├── time_scale.ex              # TimeScale options
│       ├── price_scale.ex             # PriceScale options
│       ├── price_line.ex              # PriceLine struct
│       ├── marker.ex                  # Series marker struct
│       ├── encoder.ex                 # Struct → camelCase JSON
│       └── live/
│           ├── chart_component.ex     # Phoenix function component
│           └── helpers.ex             # push_data, push_update, etc.
├── assets/
│   ├── js/
│   │   └── hooks/
│   │       └── lightweight_charts.js  # LiveView hook
│   └── vendor/
│       └── lightweight-charts.mjs     # Vendored JS library
├── priv/
│   └── static/
│       └── lightweight_charts.js      # Built/bundled hook for distribution
├── test/
│   ├── lightweight_charts/
│   │   ├── chart_test.exs
│   │   ├── series_test.exs
│   │   ├── encoder_test.exs
│   │   └── live/
│   │       └── chart_component_test.exs
│   └── test_helper.exs
├── examples/
│   └── demo/                          # Phoenix demo app
├── mix.exs
├── README.md
└── LICENSE
```

## Testing Strategy

- **Config layer:** ExUnit tests for struct building, option merging, JSON encoding, snake-to-camel conversion, time format handling.
- **LiveView layer:** `Phoenix.LiveViewTest` for component rendering, data attributes, event helpers.
- **JS hook:** Unit tests verifying chart initialization from JSON and event handling.
- **Demo app:** Integration test — if the demo works, the full stack works.

## Dependencies

- `jason` — JSON encoding (required).
- `phoenix_live_view` — Optional dependency, required only for the LiveView layer.
- lightweight-charts v5.1.0 — Vendored JS, not a mix dependency.

## License

Apache 2.0, matching the lightweight-charts library. TradingView attribution required per upstream license.
