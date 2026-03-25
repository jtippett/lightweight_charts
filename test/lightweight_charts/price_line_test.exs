defmodule LightweightCharts.PriceLineTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.PriceLine
  alias LightweightCharts.Encoder

  test "creates and encodes a price line" do
    pl =
      PriceLine.new(
        price: 150.0,
        color: "#ff0000",
        line_width: 2,
        line_style: :dashed,
        title: "Target"
      )

    encoded = Encoder.encode(pl)

    assert encoded["price"] == 150.0
    assert encoded["color"] == "#ff0000"
    assert encoded["lineWidth"] == 2
    assert encoded["lineStyle"] == 2
    assert encoded["title"] == "Target"
  end
end
