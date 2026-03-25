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
