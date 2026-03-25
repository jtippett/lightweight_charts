defmodule LightweightCharts.TimeScale do
  @moduledoc """
  Time scale (horizontal axis) options.

  ## Examples

      TimeScale.new(time_visible: true, bar_spacing: 10, right_offset: 5)
  """

  defstruct [
    :right_offset,
    :bar_spacing,
    :min_bar_spacing,
    :fix_left_edge,
    :fix_right_edge,
    :lock_visible_time_range_on_resize,
    :right_bar_stays_on_scroll,
    :border_visible,
    :border_color,
    :visible,
    :time_visible,
    :seconds_visible,
    :shift_visible_range_on_new_bar,
    :ticks_visible,
    :uniform_distribution,
    :minimum_height,
    :allow_bold_labels
  ]

  @type t :: %__MODULE__{
          right_offset: number() | nil,
          bar_spacing: number() | nil,
          min_bar_spacing: number() | nil,
          fix_left_edge: boolean() | nil,
          fix_right_edge: boolean() | nil,
          lock_visible_time_range_on_resize: boolean() | nil,
          right_bar_stays_on_scroll: boolean() | nil,
          border_visible: boolean() | nil,
          border_color: String.t() | nil,
          visible: boolean() | nil,
          time_visible: boolean() | nil,
          seconds_visible: boolean() | nil,
          shift_visible_range_on_new_bar: boolean() | nil,
          ticks_visible: boolean() | nil,
          uniform_distribution: boolean() | nil,
          minimum_height: number() | nil,
          allow_bold_labels: boolean() | nil
        }

  @doc "Creates a new TimeScale with the given options."
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)
end
