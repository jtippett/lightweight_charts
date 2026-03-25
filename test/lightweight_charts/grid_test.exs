defmodule LightweightCharts.GridTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Grid
  alias LightweightCharts.Encoder

  describe "new/1" do
    test "creates grid with defaults (all nil)" do
      grid = Grid.new()
      assert grid.vert_lines_visible == nil
      assert grid.horz_lines_visible == nil
    end

    test "accepts all options" do
      grid =
        Grid.new(
          vert_lines_visible: false,
          vert_lines_color: "#333",
          vert_lines_style: :dashed,
          horz_lines_visible: true,
          horz_lines_color: "#444",
          horz_lines_style: :dotted
        )

      assert grid.vert_lines_visible == false
      assert grid.vert_lines_color == "#333"
      assert grid.vert_lines_style == :dashed
    end
  end

  describe "encoding" do
    test "encodes to nested vertLines/horzLines structure" do
      grid = Grid.new(vert_lines_visible: false, horz_lines_color: "#444")
      encoded = Encoder.encode(grid)

      assert encoded == %{
               "vertLines" => %{"visible" => false},
               "horzLines" => %{"color" => "#444"}
             }
    end
  end
end
