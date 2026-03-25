defmodule LightweightCharts.MarkerTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Marker
  alias LightweightCharts.Encoder

  test "creates and encodes a marker" do
    marker =
      Marker.new(
        time: ~U[2024-01-15 00:00:00Z],
        position: :above_bar,
        shape: :arrow_up,
        color: "#26a69a",
        text: "Buy"
      )

    encoded = Encoder.encode(marker)

    assert encoded["time"] == 1_705_276_800
    assert encoded["position"] == "aboveBar"
    assert encoded["shape"] == "arrowUp"
    assert encoded["color"] == "#26a69a"
    assert encoded["text"] == "Buy"
  end

  test "encodes Date time as string" do
    marker =
      Marker.new(
        time: ~D[2024-01-15],
        position: :below_bar,
        shape: :arrow_down,
        color: "#f00"
      )

    encoded = Encoder.encode(marker)

    assert encoded["time"] == "2024-01-15"
    assert encoded["position"] == "belowBar"
    assert encoded["shape"] == "arrowDown"
  end
end
