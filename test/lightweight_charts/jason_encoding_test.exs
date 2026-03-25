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
