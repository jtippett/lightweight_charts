defmodule LightweightChartsTest do
  use ExUnit.Case, async: true

  setup_all do
    Code.ensure_loaded!(LightweightCharts)
    :ok
  end

  test "top-level module exposes chart/1 function component" do
    assert function_exported?(LightweightCharts, :chart, 1)
  end

  test "top-level module exposes push_data/4" do
    assert function_exported?(LightweightCharts, :push_data, 4)
  end

  test "top-level module exposes push_update/4" do
    assert function_exported?(LightweightCharts, :push_update, 4)
  end

  test "top-level module exposes push_options/4" do
    assert function_exported?(LightweightCharts, :push_options, 4)
  end

  test "top-level module exposes fit_content/2" do
    assert function_exported?(LightweightCharts, :fit_content, 2)
  end

  test "top-level module exposes set_visible_range/4" do
    assert function_exported?(LightweightCharts, :set_visible_range, 4)
  end

  test "top-level module exposes set_markers/4" do
    assert function_exported?(LightweightCharts, :set_markers, 4)
  end
end
