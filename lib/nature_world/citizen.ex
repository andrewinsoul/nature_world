defmodule NatureWorld.Citizen do
  use GenServer

  defstruct [
    :id,
    :pid,
    :generation,
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
    generation = NatureWorld.CitizenSupervisor.record_start(attrs.id)

    citizen =
      attrs
      |> Map.put(:pid, self())
      |> Map.put(:generation, generation)
      |> then(&struct(__MODULE__, &1))

    NatureWorld.CitizenSupervisor.put_position(
      citizen.id,
      citizen.x,
      citizen.y
    )

    schedule_tick()

    if generation > 1 do
      Phoenix.PubSub.broadcast(
        NatureWorld.PubSub,
        "events",
        {:citizen_restarted, citizen.id, generation}
      )
    end

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

  def crash(id) do
    case lookup(id) do
      {:ok, pid} ->
        Phoenix.PubSub.broadcast(NatureWorld.PubSub, "events", {:citizen_crashed, id})
        GenServer.stop(pid, :crashed)

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

    proposed = %{
      x: clamp(citizen.x + dx, 0, 880),
      y: clamp(citizen.y + dy, 0, 680)
    }

    if valid_position?(citizen.id, proposed) do
      NatureWorld.CitizenSupervisor.put_position(
        citizen.id,
        proposed.x,
        proposed.y
      )

      %{citizen | x: proposed.x, y: proposed.y}
    else
      citizen
    end
  end

  @impl true
  def terminate(_reason, citizen) do
    NatureWorld.CitizenSupervisor.delete_position(citizen.id)
    :ok
  end

  defp valid_position?(citizen_id, %{x: x, y: y}) do
    NatureWorld.CitizenSupervisor.positions()
    |> Enum.all?(fn {other_id, other_x, other_y} ->
      if other_id == citizen_id do
        true
      else
        distance =
          :math.sqrt(
            :math.pow(x - other_x, 2) +
              :math.pow(y - other_y, 2)
          )

        distance >= 100
      end
    end)
  end

  defp clamp(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end

  def id(pid) do
    GenServer.call(pid, :id)
  end

  defp via(id) do
    {:via, Registry, {NatureWorld.Registry, id}}
  end
end
