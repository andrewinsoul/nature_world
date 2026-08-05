defmodule NatureWorld.Citizen do
  use GenServer

  defstruct [
    :id,
    :x,
    :y,
    energy: 100,
    state: :idle
  ]

  ## Client

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  ## Server

  @impl true
  def init(attrs) do
    citizen =
      struct(__MODULE__, attrs)

    schedule_tick()

    {:ok, citizen}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:id, _from, citizen) do
    {:reply, citizen.id, citizen}
  end

  @impl true
  def handle_info(:tick, citizen) do
    citizen = wander(citizen)
    maybe_wave(citizen)

    schedule_tick()

    {:noreply, citizen}
  end

  defp schedule_tick do
    Process.send_after(
      self(),
      :tick,
      Enum.random(200..450)
    )
  end

  defp wander(citizen) do
    dx = Enum.random(-3..3)
    dy = Enum.random(-3..3)

    citizen
    |> Map.update!(:x, &clamp(&1 + dx, 0, 880))
    |> Map.update!(:y, &clamp(&1 + dy, 0, 680))
  end

  defp clamp(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end

  def id(pid) do
    GenServer.call(pid, :id)
  end

  defp maybe_wave(citizen) do
    if :rand.uniform() < 0.03 do
      IO.puts("#{citizen.id} says hello 👋")
    end
  end
end
