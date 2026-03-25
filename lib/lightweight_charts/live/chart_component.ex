defmodule LightweightCharts.Live.ChartComponent do
  @moduledoc """
  Phoenix function component for rendering a lightweight chart.

  ## Usage

      <LightweightCharts.Live.ChartComponent.chart
        id="price-chart"
        chart={@chart_config}
        class="h-96 w-full"
      />

  The component renders a `div` with the `LightweightCharts` hook attached.
  Chart configuration is passed via a `data-config` attribute as JSON.

  Use `phx-update="ignore"` to prevent LiveView from patching the chart DOM.
  Data updates are handled via server-pushed events, not DOM diffing.
  """

  use Phoenix.Component

  alias LightweightCharts.Chart

  attr :id, :string, required: true, doc: "Unique DOM ID for the chart container"
  attr :chart, Chart, required: true, doc: "Chart configuration struct"
  attr :class, :string, default: nil, doc: "CSS class(es) for the container div"
  attr :style, :string, default: nil, doc: "Inline CSS styles for the container div"
  attr :rest, :global, doc: "Additional HTML attributes"

  @doc "Renders a lightweight chart container."
  def chart(assigns) do
    config_json = assigns.chart |> Chart.to_json() |> Jason.encode!()
    assigns = assign(assigns, :config_json, config_json)

    ~H"""
    <div
      id={@id}
      phx-hook="LightweightCharts"
      phx-update="ignore"
      data-config={@config_json}
      class={@class}
      style={@style}
      {@rest}
    />
    """
  end
end
