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
    GenServer.start_link(
      __MODULE__,
      attrs,
      name: via(attrs.id)
    )
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
  def handle_cast({:greet, from}, citizen) do
    citizen =
      %{citizen | state: :excited}

    Phoenix.PubSub.broadcast(
      NatureWorld.PubSub,
      "events",
      {:message_sent,
       %NatureWorld.Message{
         id: System.unique_integer([:positive]),
         from: from,
         to: citizen.id,
         started_at: System.monotonic_time()
       }}
    )

    Process.send_after(self(), :calm_down, 400)

    {:noreply, citizen}
  end

  @impl true
  def handle_info(:tick, citizen) do
    citizen = wander(citizen)
    maybe_greet(citizen)

    schedule_tick()

    {:noreply, citizen}
  end

  @impl true
  def handle_info(:calm_down, citizen) do
    citizen =
      %{citizen | state: :idle}

    {:noreply, citizen}
  end

  def lookup(id) do
    case Registry.lookup(NatureWorld.Registry, id) do
      [{pid, _}] -> {:ok, pid}
      [] -> :error
    end
  end

  def greet(target_id, from_id) do
    case lookup(target_id) do
      {:ok, pid} ->
        GenServer.cast(pid, {:greet, from_id})

      :error ->
        :ok
    end
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

  defp maybe_greet(citizen) do
    if :rand.uniform() < 0.03 do
      target =
        Enum.random(1..50)

      if target != citizen.id do
        greet(target, citizen.id)
      end
    end
  end

  defp via(id) do
    {:via, Registry, {NatureWorld.Registry, id}}
  end
end
