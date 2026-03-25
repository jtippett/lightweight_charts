defmodule LightweightCharts.EncoderTest do
  use ExUnit.Case, async: true

  alias LightweightCharts.Encoder

  describe "to_camel_case/1" do
    test "converts snake_case atom to camelCase string" do
      assert Encoder.to_camel_case(:background_color) == "backgroundColor"
      assert Encoder.to_camel_case(:up_color) == "upColor"
      assert Encoder.to_camel_case(:line_width) == "lineWidth"
    end

    test "single word stays lowercase" do
      assert Encoder.to_camel_case(:color) == "color"
      assert Encoder.to_camel_case(:visible) == "visible"
    end

    test "converts string keys" do
      assert Encoder.to_camel_case("bar_spacing") == "barSpacing"
    end
  end

  describe "encode/1" do
    test "converts a flat map with atom keys to camelCase string keys" do
      input = %{up_color: "#26a69a", down_color: "#ef5350", wick_visible: true}

      result = Encoder.encode(input)

      assert result == %{
               "upColor" => "#26a69a",
               "downColor" => "#ef5350",
               "wickVisible" => true
             }
    end

    test "converts nested maps" do
      input = %{
        layout: %{background_color: "#fff", text_color: "#000"},
        time_scale: %{time_visible: true}
      }

      result = Encoder.encode(input)

      assert result == %{
               "layout" => %{"backgroundColor" => "#fff", "textColor" => "#000"},
               "timeScale" => %{"timeVisible" => true}
             }
    end

    test "passes through scalar values unchanged" do
      assert Encoder.encode("hello") == "hello"
      assert Encoder.encode(42) == 42
      assert Encoder.encode(true) == true
      assert Encoder.encode(nil) == nil
    end

    test "converts lists of maps" do
      input = [%{line_width: 2}, %{line_width: 3}]
      result = Encoder.encode(input)
      assert result == [%{"lineWidth" => 2}, %{"lineWidth" => 3}]
    end

    test "strips nil values from maps" do
      input = %{color: "#fff", line_width: nil, visible: true}
      result = Encoder.encode(input)
      assert result == %{"color" => "#fff", "visible" => true}
    end

    test "converts DateTime to Unix timestamp" do
      dt = ~U[2024-01-15 12:30:00Z]
      assert Encoder.encode_time(dt) == 1705321800
    end

    test "converts NaiveDateTime to Unix timestamp" do
      ndt = ~N[2024-01-15 12:30:00]
      assert Encoder.encode_time(ndt) == 1705321800
    end

    test "converts Date to YYYY-MM-DD string" do
      d = ~D[2024-01-15]
      assert Encoder.encode_time(d) == "2024-01-15"
    end

    test "passes through integers as Unix timestamps" do
      assert Encoder.encode_time(1705318200) == 1705318200
    end

    test "passes through YYYY-MM-DD strings" do
      assert Encoder.encode_time("2024-01-15") == "2024-01-15"
    end

    test "converts atoms to lowercase strings for enum values" do
      assert Encoder.encode_enum(:solid) == 0
      assert Encoder.encode_enum(:dotted) == 1
      assert Encoder.encode_enum(:dashed) == 2
      assert Encoder.encode_enum(:large_dashed) == 3
      assert Encoder.encode_enum(:sparse_dotted) == 4
    end
  end
end
