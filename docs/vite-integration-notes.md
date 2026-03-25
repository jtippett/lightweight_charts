# Vite Integration Notes

## Vendored JS: Use the Standalone Build

The vendored file at `assets/vendor/lightweight-charts.mjs` was originally copied from the non-standalone TradingView build (`lightweight-charts.production.mjs`). That build has an external `import` for `"fancy-canvas"`, which works with esbuild (it resolves from node_modules) but fails under Vite because Vite won't resolve bare specifiers outside its configured dependency tree.

### Fix

Replace the vendored file with the **standalone** build, which bundles `fancy-canvas` inline:

```bash
cp lightweight-charts/dist/lightweight-charts.standalone.production.mjs \
   assets/vendor/lightweight-charts.mjs
```

This is a one-line fix in the library itself. The standalone build is functionally identical -- it just doesn't have the external `fancy-canvas` import.

## Vite Setup (phoenix_vite)

The README documents esbuild and bun paths (`../../deps/lightweight_charts`). That path does not work with Vite because:

1. **Path deps aren't symlinked into `deps/`** -- Mix path deps are referenced in-place, so `deps/lightweight_charts/` doesn't exist on disk.
2. **Vite's module resolution** doesn't follow the same `../../` traversal that esbuild does. Bare or relative imports outside the Vite root (`assets/`) hit `fs.allow` restrictions and `vite:import-analysis` errors.

### Recommended Vite Configuration

Add a resolve alias in `vite.config.mjs` pointing to the library's JS entry point. The path depends on how the dep is referenced:

#### Hex dependency (deps/ exists)

```javascript
// vite.config.mjs
resolve: {
  alias: {
    "lightweight_charts": "../deps/lightweight_charts/assets/js/index.js",
  },
},
```

#### Path dependency (deps/ does NOT exist)

```javascript
// vite.config.mjs
resolve: {
  alias: {
    "lightweight_charts": "/absolute/path/to/lightweight-charts-ex/assets/js/index.js",
  },
},
```

Then import in your hooks file:

```javascript
import { LightweightChartsHook } from "lightweight_charts";
```

### README suggestion

Add a "With Vite (phoenix_vite)" section to the README alongside the existing esbuild and bun sections, documenting the alias approach above.

## Summary of Issues Encountered

| Issue | Cause | Fix |
|---|---|---|
| `Failed to resolve import "fancy-canvas"` | Vendored `.mjs` uses non-standalone build with external `fancy-canvas` dep | Swap to `lightweight-charts.standalone.production.mjs` |
| `Failed to resolve import "../../deps/lightweight_charts"` | Vite can't resolve `../../deps/` paths the way esbuild can | Add `resolve.alias` in `vite.config.mjs` |
| `Failed to resolve import "lightweight_charts"` (bare specifier) | Vite alias pointing to `../deps/` which doesn't exist for path deps | Use absolute path to library source in alias |
