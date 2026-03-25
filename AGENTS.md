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

#### esbuild (Phoenix default) or bun

```javascript
import { LightweightChartsHook } from "../../deps/lightweight_charts"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { LightweightCharts: LightweightChartsHook }
})
```

#### Vite (phoenix_vite)

Vite cannot resolve the `../../deps/` path the way esbuild can. Add a resolve alias in `vite.config.mjs`:

```javascript
// Hex dependency (deps/ exists on disk):
resolve: {
  alias: {
    "lightweight_charts": "../deps/lightweight_charts/assets/js/index.js",
  },
},

// Path dependency (deps/ does NOT exist — Mix references the source directly):
resolve: {
  alias: {
    "lightweight_charts": "/absolute/path/to/lightweight-charts-ex/assets/js/index.js",
  },
},
```

Then import using the bare specifier:

```javascript
import { LightweightChartsHook } from "lightweight_charts"
```

**Vite also requires the standalone JS build.** The default vendored `lightweight-charts.mjs` uses a non-standalone build that has an external `import "fancy-canvas"`. esbuild resolves this from node_modules, but Vite fails with `Failed to resolve import "fancy-canvas"`. Fix by replacing the vendored file:

```bash
cp lightweight-charts/dist/lightweight-charts.standalone.production.mjs \
   assets/vendor/lightweight-charts.mjs
```

#### Phoenix 1.8 hook wiring

In Phoenix 1.8, `app.js` includes colocated hooks. Spread them alongside the LightweightCharts hook:

```javascript
import {hooks as colocatedHooks} from "phoenix-colocated/demo"
import {LightweightChartsHook} from "../../deps/lightweight_charts"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...colocatedHooks, LightweightCharts: LightweightChartsHook}
})
```

#### Resolution chain

The `package.json` at the package root tells the bundler to resolve `lightweight_charts` to `assets/js/index.js`, which re-exports the hook from `assets/js/hooks/lightweight_charts.js`. The hook imports the vendored library from `assets/vendor/lightweight-charts.mjs`.

**This is the most common failure point.** If the chart div appears but nothing renders, the hook isn't registered. Check:
- The import path resolves correctly for your bundler
- The hook name in `hooks: { LightweightCharts: ... }` matches `phx-hook="LightweightCharts"` on the div
- The vendored `.mjs` file exists at the expected relative path from the hook
- With Vite: you're using the standalone build (no `fancy-canvas` external import)

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

## Development Commands

```bash
mix test            # 75 tests
mix test --cover    # with coverage
mix format          # format code
mix docs            # generate HexDocs
```

## Running the Demo

```bash
cd examples/demo
mix deps.get
mix phx.server
# Visit http://localhost:4000
```

## Code Conventions

- **Builder API uses pipeline style**: `Chart.new() |> Chart.layout(...) |> Chart.add_series(...)`
- **All struct fields use snake_case**; the `Encoder` module converts to camelCase for the JS side
- **Config and data are separate concerns** — config defines chart structure (series types, colors, options), `push_data` sends the actual values. This keeps the initial config lightweight and data streamable.

## Vendored JS Build

The file `assets/vendor/lightweight-charts.mjs` is the **standalone** production build from TradingView (bundles `fancy-canvas` inline). This is important — the non-standalone build has an external `import "fancy-canvas"` that breaks Vite and any bundler without `fancy-canvas` in its module resolution path. If you ever need to rebuild the vendored file:

```bash
cd lightweight-charts && npm install && npm run build:prod
cp dist/lightweight-charts.standalone.production.mjs ../assets/vendor/lightweight-charts.mjs
```

## Bundler Compatibility Matrix

The vendored standalone build works with all three bundlers out of the box:

| Bundler | Import path | Extra config needed | Notes |
|---|---|---|---|
| esbuild | `../../deps/lightweight_charts` | None | Phoenix default |
| bun | `../../deps/lightweight_charts` | None | Drop-in esbuild replacement |
| Vite | Bare specifier via `resolve.alias` | `resolve.alias` in `vite.config.mjs` | See Vite section above |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Chart div appears but is empty | Hook not registered | Check import path + hooks object in LiveSocket |
| `Failed to resolve import "fancy-canvas"` | Non-standalone vendored build under Vite | Swap to `lightweight-charts.standalone.production.mjs` |
| `Failed to resolve import "../../deps/lightweight_charts"` | Vite can't resolve `../../deps/` paths | Add `resolve.alias` in `vite.config.mjs` |
| Chart renders but no data | `push_data` called before `connected?(socket)` | Guard data pushes with `if connected?(socket)` |
| Chart renders but is 0px tall | Container has no explicit height | Add `class="h-96"` or `style="height: 400px"` to the component |
| Series ID mismatch | `push_data` series_id doesn't match `Series.*(id: ...)` | Ensure IDs match exactly (string comparison) |

## Phoenix 1.8 Integration Notes

These are real-world learnings from integrating with Phoenix 1.8 projects:

- **Tailwind v4**: No `tailwind.config.js` needed. CSS uses `@import "tailwindcss"` syntax in `app.css`. Chart container sizing works with arbitrary value classes like `class="h-[600px]"`.
- **Colocated hooks**: Phoenix 1.8 generates a `colocatedHooks` import. Spread it alongside the LightweightCharts hook (see hook wiring section above). Colocated hook names start with `.` — the LightweightCharts hook does not (it's an external hook).
- **`phx-update="ignore"` is mandatory**: The chart component sets this automatically. If you build a custom wrapper, you MUST include it — otherwise LiveView will patch the chart DOM and destroy the canvas.
- **`phx-hook` requires a DOM id**: The chart component requires `id` as a required attribute for this reason.
- **`push_event` socket rebinding**: Always rebind or return the socket after `push_event`. The helpers (`push_data`, `push_update`, etc.) return the socket — pipe them.
- **Vendor imports**: Phoenix 1.8 only supports `app.js` and `app.css` bundles. You cannot reference external vendor scripts via `<script src>` in layouts. The vendored `lightweight-charts.mjs` is imported into the JS bundle, not loaded separately.

## Known Limitations

- Only standard time-based charts (`createChart`). Yield curve and options charts are not supported yet.
- Custom series plugins are not exposed.
- Watermark plugins are not exposed.
- The `Encoder` merges all enum namespaces into a flat map — `:normal` maps to 0 for both crosshair mode and price scale mode (works today since both are 0, but fragile if upstream changes values).
