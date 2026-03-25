# AGENTS.md — LightweightCharts Integration Guide

## What This Is

`lightweight_charts` is an Elixir package that wraps TradingView's [Lightweight Charts](https://github.com/tradingview/lightweight-charts) v5.1.0 for Phoenix LiveView. It has three layers:

1. **Config layer** (pure Elixir) — Structs that model chart configuration. No Phoenix dependency.
2. **LiveView layer** — A function component + helper functions that bridge Elixir to the JS hook via `push_event`.
3. **JS layer** — A LiveView hook that initializes lightweight-charts on the client, manages series, handles resize, and bridges events bidirectionally.

## Project Structure

```
.
├── lib/
│   ├── lightweight_charts.ex                # Public API facade (component + delegates)
│   └── lightweight_charts/
│       ├── chart.ex                         # Chart struct, builder pipeline, to_json
│       ├── series.ex                        # Series struct (6 types: line, area, bar, candlestick, histogram, baseline)
│       ├── encoder.ex                       # snake_case → camelCase, time encoding, enum mapping
│       ├── layout.ex                        # Layout options (background, text color, font)
│       ├── grid.ex                          # Grid lines (vert/horz visibility, color, style)
│       ├── crosshair.ex                     # Crosshair mode and line styling
│       ├── time_scale.ex                    # Horizontal axis options
│       ├── price_scale.ex                   # Vertical axis options
│       ├── price_line.ex                    # Horizontal price line markers
│       ├── marker.ex                        # Point markers on series
│       └── live/
│           ├── chart_component.ex           # Phoenix function component (<LightweightCharts.chart />)
│           └── helpers.ex                   # push_data, push_update, push_options, etc.
├── assets/
│   ├── js/
│   │   ├── index.js                         # Entry point: re-exports LightweightChartsHook
│   │   └── hooks/
│   │       └── lightweight_charts.js        # The LiveView hook (core JS logic)
│   └── vendor/
│       └── lightweight-charts.mjs           # Vendored lightweight-charts v5.1.0 (177K ESM)
├── test/                                     # ExUnit tests mirroring lib/ structure
├── package.json                              # npm package resolution (points to assets/js/index.js)
├── mix.exs                                   # Hex package config
├── examples/demo/                            # Working Phoenix demo app
└── lightweight-charts/                       # Upstream JS library source (not part of the package)
```

## How the Three Layers Connect

### Data flow: Server → Client

```
Elixir struct (Chart, Series, etc.)
  → Chart.to_json/1 converts to plain maps with camelCase keys
  → Jason.encode!/1 serializes to JSON string
  → Stored in data-config attribute on the div
  → JS hook reads it in mounted(), calls createChart() + addSeries()

For updates after mount:
  LightweightCharts.push_data(socket, chart_id, series_id, data)
  → Phoenix.LiveView.push_event(socket, "lc:chart_id:set_data", payload)
  → JS hook's handleEvent receives it, calls series.setData(data)
```

### Data flow: Client → Server

```
User clicks chart
  → JS hook's subscribeClick handler fires
  → hook calls this.pushEvent("lc:click", payload)
  → LiveView receives handle_event("lc:click", params, socket)
```

### Event naming convention

Server-to-client events: `lc:{chart_id}:{action}` — e.g., `lc:price-chart:set_data`
Client-to-server events: `lc:{event_type}` — e.g., `lc:click`, `lc:crosshair_move`

## What Needs to Be Where (Integration Checklist)

When integrating this library into a Phoenix project, three things must be in place:

### 1. Elixir dependency (mix.exs)

```elixir
{:lightweight_charts, "~> 0.1.0"}
# or for local development:
{:lightweight_charts, path: "/path/to/lightweight_charts"}
```

### 2. JS hook registration (assets/js/app.js)

The hook must be imported and registered with the LiveSocket. The import path depends on the bundler:

```javascript
// esbuild (Phoenix default) — resolve from deps/
import { LightweightChartsHook } from "../../deps/lightweight_charts"

// Then add to hooks:
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

The `package.json` at the package root tells the bundler to resolve `lightweight_charts` to `assets/js/index.js`, which re-exports the hook from `assets/js/hooks/lightweight_charts.js`. The hook imports the vendored library from `assets/vendor/lightweight-charts.mjs`.

**This is the most common failure point.** If the chart div appears but nothing renders, the hook isn't registered. Check:
- The import path resolves correctly
- The hook name in `hooks: { LightweightCharts: ... }` matches `phx-hook="LightweightCharts"` on the div
- The vendored `.mjs` file exists at the expected relative path from the hook

### 3. LiveView code (your app)

Minimum working example:

```elixir
defmodule MyAppWeb.ChartLive do
  use MyAppWeb, :live_view
  alias LightweightCharts.{Chart, Series}

  def mount(_params, _session, socket) do
    chart =
      Chart.new()
      |> Chart.add_series(Series.line(id: "prices"))

    socket = assign(socket, chart: chart)

    if connected?(socket) do
      data = [%{time: ~D[2024-01-01], value: 100}, %{time: ~D[2024-01-02], value: 105}]
      socket = LightweightCharts.push_data(socket, "my-chart", "prices", data)
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <LightweightCharts.chart id="my-chart" chart={@chart} class="h-96 w-full" />
    """
  end
end
```

Key rules:
- The `id` attribute on the component MUST match the `chart_id` argument in `push_data` and friends
- Series are identified by the `id:` you pass to `Series.line(id: "prices")` — this MUST match the `series_id` in `push_data`
- Data should only be pushed after `connected?(socket)` is true (otherwise there's no JS hook to receive it)
- The container div needs explicit height (e.g., `class="h-96"`) — lightweight-charts won't render in a zero-height container

## Encoder Details

The `Encoder` module handles the Elixir → JS translation:

- **Snake case → camelCase**: `background_color` → `backgroundColor`
- **Time encoding**: `~U[2024-01-15 00:00:00Z]` → Unix timestamp, `~D[2024-01-15]` → `"2024-01-15"`
- **Enum mapping**: `:magnet` → `1`, `:dashed` → `2`, `:logarithmic` → `1`
- **Nil stripping**: Fields set to `nil` are omitted from the JSON output
- **Custom struct encoding**: Layout, Grid, Crosshair, PriceScale, Series, PriceLine, and Marker have custom `to_map/1` functions because their encoding isn't a simple field rename (e.g., Layout nests `background_color` under `background.type/color`)

## Series Types

| Elixir constructor | JS definition | Data shape |
|---|---|---|
| `Series.line(id: "x")` | `LineSeries` | `%{time: ..., value: n}` |
| `Series.area(id: "x")` | `AreaSeries` | `%{time: ..., value: n}` |
| `Series.bar(id: "x")` | `BarSeries` | `%{time: ..., open: n, high: n, low: n, close: n}` |
| `Series.candlestick(id: "x")` | `CandlestickSeries` | `%{time: ..., open: n, high: n, low: n, close: n}` |
| `Series.histogram(id: "x")` | `HistogramSeries` | `%{time: ..., value: n}` |
| `Series.baseline(id: "x")` | `BaselineSeries` | `%{time: ..., value: n}` |

## JS Hook Internals

The hook (`assets/js/hooks/lightweight_charts.js`) manages:

- **Chart lifecycle**: Creates chart in `mounted()`, destroys in `destroyed()`
- **Series registry**: `this._series` maps string IDs to lightweight-charts `ISeriesApi` instances
- **ResizeObserver**: Automatically resizes the chart when the container dimensions change
- **Server events**: Listens for `lc:{id}:set_data`, `lc:{id}:update`, `lc:{id}:apply_options`, `lc:{id}:fit_content`, `lc:{id}:set_visible_range`, `lc:{id}:set_markers`
- **Client events**: Subscribes to `click`, `dblClick`, `crosshairMove`, `visibleTimeRangeChange` and forwards them via `pushEvent`

## Running the Demo

```bash
cd examples/demo
mix deps.get
mix phx.server
# Visit http://localhost:4000
```

## Running Tests

```bash
mix test            # 75 tests
mix test --cover    # with coverage
```

## Known Limitations

- Only standard time-based charts (`createChart`). Yield curve and options charts are not supported yet.
- Custom series plugins are not exposed.
- Watermark plugins are not exposed.
- The `Encoder` merges all enum namespaces into a flat map — `:normal` maps to 0 for both crosshair mode and price scale mode (works today since both are 0, but fragile if upstream changes values).
