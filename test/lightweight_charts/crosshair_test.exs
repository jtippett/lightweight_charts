defmodule LightweightCharts.CrosshairTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Crosshair
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates crosshair with mode" do
      ch = Crosshair.new(mode: :magnet)
      assert ch.mode == :magnet
    end

    test "accepts vert/horz line options" do
      ch =
        Crosshair.new(
          mode: :normal,
          vert_line_color: "#999",
          vert_line_width: 2,
          vert_line_style: :dashed,
          vert_line_visible: true,
          vert_line_label_visible: false,
          horz_line_color: "#aaa"
        )

      assert ch.vert_line_color == "#999"
      assert ch.horz_line_color == "#aaa"
    end
  end

  describe "encoding" do
    test "encodes mode to integer and nests line options" do
      ch = Crosshair.new(mode: :magnet, vert_line_color: "#999", horz_line_visible: false)
      encoded = Encoder.encode(ch)

      assert encoded["mode"] == 1
      assert encoded["vertLine"]["color"] == "#999"
      assert encoded["horzLine"]["visible"] == false
    end
  end
end
