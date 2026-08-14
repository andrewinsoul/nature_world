defmodule NatureWorld.Simulation do
  use GenServer

  @tick_rate 250

  ## Client

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def state do
    GenServer.call(__MODULE__, :snapshot)
  end

  ## Server

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(
      NatureWorld.PubSub,
      "events"
    )

    state = %{
      tick: 0,
      citizen_ids: spawn_citizens(),
      messages: [],
      crashed_ids: MapSet.new()
    }

    schedule_tick()

    {:ok, state}
  end

  @impl true
  def handle_info({:message_sent, message}, state) do
    state =
      %{
        state
        | messages: [message | state.messages]
      }

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:citizen_restarted, id, _generation}, state) do
    state =
      %{state | crashed_ids: MapSet.delete(state.crashed_ids, id)}

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:citizen_crashed, id}, state) do
    state =
      %{state | crashed_ids: MapSet.put(state.crashed_ids, id)}

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state =
      state
      |> Map.update!(:tick, &(&1 + 1))
      |> expire_messages()

    broadcast_snapshot(state)

    schedule_tick()

    {:noreply, state}
  end

  defp snapshot(state) do
    citizens =
      state.citizen_ids
      |> Enum.flat_map(fn id ->
        if MapSet.member?(state.crashed_ids, id) do
          []
        else
          case NatureWorld.Citizen.lookup(id) do
            {:ok, pid} ->
              [NatureWorld.Citizen.state(pid)]

            :error ->
              []
          end
        end
      end)

    %{
      tick: state.tick,
      citizens: citizens,
      messages: state.messages,
      supervisor: NatureWorld.CitizenSupervisor.stats()
    }
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, snapshot(state), state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_rate)
  end

  defp spawn_citizens do
    positions = random_positions(20, [])

    for {{x, y}, id} <- Enum.with_index(positions, 1) do
      {:ok, _pid} =
        NatureWorld.CitizenSupervisor.start_citizen(%{
          id: id,
          x: x,
          y: y
        })

      id
    end
  end

  defp random_positions(0, positions), do: positions

  defp random_positions(count, positions) do
    position = {
      Enum.random(40..860),
      Enum.random(40..660)
    }

    if valid_position?(position, positions) do
      random_positions(count - 1, [position | positions])
    else
      random_positions(count, positions)
    end
  end

  defp valid_position?({x, y}, positions) do
    Enum.all?(positions, fn {other_x, other_y} ->
      distance =
        :math.sqrt(
          :math.pow(x - other_x, 2) +
            :math.pow(y - other_y, 2)
        )

      distance >= 100
    end)
  end

  defp broadcast_snapshot(state) do
    Phoenix.PubSub.broadcast(
      NatureWorld.PubSub,
      "simulation",
      {:tick, snapshot(state)}
    )
  end

  defp expire_messages(state) do
    now = System.monotonic_time()

    messages =
      Enum.filter(state.messages, fn message ->
        System.convert_time_unit(
          now - message.started_at,
          :native,
          :millisecond
        ) < 1000
      end)

    %{state | messages: messages}
  end
end
