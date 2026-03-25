defmodule LightweightCharts.PriceScaleTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.PriceScale
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates price scale with options" do
      ps = PriceScale.new(auto_scale: true, mode: :logarithmic, visible: true)
      assert ps.auto_scale == true
      assert ps.mode == :logarithmic
    end
  end

  describe "encoding" do
    test "encodes mode as integer" do
      ps = PriceScale.new(mode: :logarithmic, visible: true, border_visible: false)
      encoded = Encoder.encode(ps)

      assert encoded["mode"] == 1
      assert encoded["visible"] == true
      assert encoded["borderVisible"] == false
    end

    test "encodes scale margins" do
      ps = PriceScale.new(scale_margin_top: 0.1, scale_margin_bottom: 0.2)
      encoded = Encoder.encode(ps)

      assert encoded["scaleMargins"] == %{"top" => 0.1, "bottom" => 0.2}
    end
  end
end
