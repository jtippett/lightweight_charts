defmodule LightweightCharts.LayoutTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Layout
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates layout with defaults" do
      layout = Layout.new()
      assert layout.background_color == nil
      assert layout.text_color == nil
      assert layout.font_size == nil
      assert layout.font_family == nil
    end

    test "creates layout with custom options" do
      layout = Layout.new(background_color: "#1a1a2e", text_color: "#e0e0e0", font_size: 14)
      assert layout.background_color == "#1a1a2e"
      assert layout.text_color == "#e0e0e0"
      assert layout.font_size == 14
    end
  end

  describe "encoding" do
    test "encodes to camelCase JSON map" do
      layout = Layout.new(background_color: "#1a1a2e", text_color: "#e0e0e0")
      encoded = Encoder.encode(layout)

      assert encoded == %{
               "background" => %{"type" => "solid", "color" => "#1a1a2e"},
               "textColor" => "#e0e0e0"
             }
    end

    test "strips nil fields" do
      layout = Layout.new(text_color: "#000")
      encoded = Encoder.encode(layout)

      assert encoded == %{"textColor" => "#000"}
    end
  end
end
