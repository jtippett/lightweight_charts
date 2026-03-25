# CLAUDE.md

## Project Overview

Elixir wrapper for TradingView Lightweight Charts v5.1, providing a Phoenix LiveView integration with declarative chart configuration and real-time data streaming via `push_event`.

## Architecture

- **Elixir side**: `LightweightCharts.Chart` and `LightweightCharts.Series` structs build chart config. `LightweightCharts.push_data/4` pushes data to the browser via LiveView events. The chart component renders a `<div>` with `phx-hook="LightweightCharts"` and `phx-update="ignore"`.
- **JS side**: A single LiveView hook (`assets/js/hooks/lightweight_charts.js`) reads `data-config` on mount, creates the chart, and listens for server-pushed events (`set_data`, `update`, `apply_options`, `fit_content`, etc.).
- **Vendored JS**: `assets/vendor/lightweight-charts.mjs` is the TradingView library. Must be the **standalone** build (bundles `fancy-canvas` inline). See `docs/vite-integration-notes.md`.

## Development Commands

- `mix test` -- run tests
- `mix format` -- format code

## Important: Vendored JS Build

The file `assets/vendor/lightweight-charts.mjs` **must** be the standalone production build from TradingView:

```bash
cp lightweight-charts/dist/lightweight-charts.standalone.production.mjs \
   assets/vendor/lightweight-charts.mjs
```

The non-standalone build (`lightweight-charts.production.mjs`) has an external `import "fancy-canvas"` that breaks Vite and any bundler that doesn't have `fancy-canvas` in its module resolution path. The standalone build is identical except it bundles `fancy-canvas` inline.

## JS Bundler Compatibility

The README documents esbuild and bun setup. Vite (used by `phoenix_vite`) requires a different approach -- see `docs/vite-integration-notes.md` for the full writeup. The short version:

- Vite needs a `resolve.alias` in `vite.config.mjs` pointing to the library's JS entry point
- The `../../deps/lightweight_charts` import path from the README does not work with Vite
- Path deps (`:lightweight_charts, path: "..."`) are not symlinked into `deps/`, so the alias must use the actual source path

## Code Conventions

- Builder API uses pipeline style: `Chart.new() |> Chart.layout(...) |> Chart.add_series(...)`
- All struct fields use snake_case; the `Encoder` module converts to camelCase for JSON
- Data is pushed separately from config -- config defines structure, `push_data` sends values
