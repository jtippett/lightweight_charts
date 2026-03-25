defmodule DemoWeb.ChartLive do
  use DemoWeb, :live_view

  alias LightweightCharts.{Chart, Series}

  @impl true
  def mount(_params, _session, socket) do
    chart =
      Chart.new()
      |> Chart.layout(background_color: "#1a1a2e", text_color: "#e0e0e0")
      |> Chart.crosshair(mode: :magnet)
      |> Chart.time_scale(time_visible: true)
      |> Chart.add_series(
        Series.candlestick(id: "candles", up_color: "#26a69a", down_color: "#ef5350")
      )
      |> Chart.add_series(
        Series.histogram(id: "volume", color: "rgba(38,166,154,0.5)", pane_index: 1)
      )
      |> Chart.on(:click)

    socket = assign(socket, chart: chart, last_close: 100.0)

    if connected?(socket) do
      Process.send_after(self(), :load_data, 100)
      Process.send_after(self(), :stream_tick, 2000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_data, socket) do
    {candles, volumes} = generate_sample_data(100)
    last_close = List.last(candles).close

    socket =
      socket
      |> LightweightCharts.push_data("price-chart", "candles", candles)
      |> LightweightCharts.push_data("price-chart", "volume", volumes)
      |> LightweightCharts.fit_content("price-chart")
      |> assign(:last_close, last_close)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:stream_tick, socket) do
    candle = generate_random_candle(socket.assigns.last_close)
    volume = %{time: candle.time, value: :rand.uniform(1000) * 100}

    socket =
      socket
      |> LightweightCharts.push_update("price-chart", "candles", candle)
      |> LightweightCharts.push_update("price-chart", "volume", volume)
      |> assign(:last_close, candle.close)

    Process.send_after(self(), :stream_tick, 1000)
    {:noreply, socket}
  end

  @impl true
  def handle_event("lc:click", params, socket) do
    IO.inspect(params, label: "Chart click")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#1a1a2e] p-8">
      <h1 class="text-2xl font-bold mb-4 text-white">LightweightCharts Demo</h1>
      <p class="text-gray-400 mb-6">
        Candlestick chart with volume histogram. Streaming random ticks every second.
      </p>
      <LightweightCharts.chart id="price-chart" chart={@chart} class="h-[600px] w-full" />
    </div>
    """
  end

  defp generate_sample_data(count) do
    base_time = DateTime.utc_now() |> DateTime.add(-count * 86400, :second)
    base_price = 100.0

    {candles, _} =
      Enum.map_reduce(1..count, base_price, fn i, prev_close ->
        time = DateTime.add(base_time, i * 86400, :second)
        open = prev_close + (:rand.uniform() - 0.5) * 2
        close = open + (:rand.uniform() - 0.5) * 4
        high = max(open, close) + :rand.uniform() * 2
        low = min(open, close) - :rand.uniform() * 2

        candle = %{time: time, open: open, high: high, low: low, close: close}
        {candle, close}
      end)

    volumes =
      Enum.map(candles, fn c ->
        %{time: c.time, value: :rand.uniform(1000) * 100}
      end)

    {candles, volumes}
  end

  defp generate_random_candle(prev_close) do
    time = DateTime.utc_now()
    open = prev_close + (:rand.uniform() - 0.5) * 2
    close = open + (:rand.uniform() - 0.5) * 4
    high = max(open, close) + :rand.uniform() * 2
    low = min(open, close) - :rand.uniform() * 2

    %{time: time, open: open, high: high, low: low, close: close}
  end
end
