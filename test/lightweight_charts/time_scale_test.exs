defmodule LightweightCharts.TimeScaleTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.TimeScale
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates time scale with options" do
      ts = TimeScale.new(time_visible: true, bar_spacing: 8, right_offset: 5)
      assert ts.time_visible == true
      assert ts.bar_spacing == 8
      assert ts.right_offset == 5
    end
  end

  describe "encoding" do
    test "encodes to camelCase" do
      ts = TimeScale.new(time_visible: true, seconds_visible: false, bar_spacing: 10)
      encoded = Encoder.encode(ts)

      assert encoded == %{
               "timeVisible" => true,
               "secondsVisible" => false,
               "barSpacing" => 10
             }
    end
  end
end
