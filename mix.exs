defmodule LightweightCharts.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/jtippett/lightweight_charts"

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
      files: ~w(lib assets package.json mix.exs README.md LICENSE)
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
