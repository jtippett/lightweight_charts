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

    # Extract data-config value — the JSON is HTML-entity encoded in the attribute
    [_, config_encoded] = Regex.run(~r/data-config="([^"]*)"/, html)

    config =
      config_encoded
      |> String.replace("&amp;", "&")
      |> String.replace("&lt;", "<")
      |> String.replace("&gt;", ">")
      |> String.replace("&quot;", "\"")
      |> Jason.decode!()

    assert length(config["series"]) == 1
    assert hd(config["series"])["type"] == "Candlestick"
  end

  test "renders with style attribute" do
    chart = Chart.new() |> Chart.add_series(Series.line(id: "s1"))
    assigns = %{chart: chart}

    html =
      rendered_to_string(~H"""
      <LightweightCharts.Live.ChartComponent.chart id="styled" chart={@chart} style="height: 400px" />
      """)

    assert html =~ ~s(style="height: 400px")
  end

  test "renders without optional attributes" do
    chart = Chart.new() |> Chart.add_series(Series.line(id: "s1"))
    assigns = %{chart: chart}

    html =
      rendered_to_string(~H"""
      <LightweightCharts.Live.ChartComponent.chart id="minimal" chart={@chart} />
      """)

    assert html =~ ~s(id="minimal")
    assert html =~ ~s(phx-hook="LightweightCharts")
    assert html =~ ~s(phx-update="ignore")
    assert html =~ ~s(data-config=)
  end
end
