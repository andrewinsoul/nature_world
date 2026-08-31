defmodule NatureWorld.Simulation do
  use GenServer

  @tick_rate 1000
  @min_tick_rate 250
  @max_tick_rate 2500
  @tick_step 250
  @initial_citizens 20

  ## Client

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def state do
    GenServer.call(__MODULE__, :snapshot)
  end

  def toggle_pause do
    GenServer.call(__MODULE__, :toggle_pause)
  end

  def faster do
    GenServer.call(__MODULE__, :faster)
  end

  def slower do
    GenServer.call(__MODULE__, :slower)
  end

  def spawn_citizen do
    GenServer.call(__MODULE__, :spawn_citizen)
  end

  def toggle_partition do
    GenServer.call(__MODULE__, :toggle_partition)
  end

  ## Server

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(NatureWorld.PubSub, "events")

    {citizen_ids, next_citizen_id} = spawn_citizens(@initial_citizens, 1)

    state = %{
      tick: 0,
      citizen_ids: citizen_ids,
      next_citizen_id: next_citizen_id,
      messages: [],
      crashed_ids: MapSet.new(),
      paused?: false,
      tick_interval_ms: @tick_rate,
      message_count: 0,
      crash_count: 0,
      spawn_count: length(citizen_ids),
      partitioned?: false
    }

    schedule_tick(state.tick_interval_ms)

    {:ok, state}
  end

  @impl true
  def handle_info({:message_sent, message}, state) do
    state =
      %{
        state
        | messages: [message | state.messages],
          message_count: state.message_count + 1
      }

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:citizen_restarted, id, _generation}, state) do
    state = %{state | crashed_ids: MapSet.delete(state.crashed_ids, id)}

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:citizen_crashed, id}, state) do
    state =
      %{
        state
        | crashed_ids: MapSet.put(state.crashed_ids, id),
          crash_count: state.crash_count + 1
      }

    broadcast_snapshot(state)

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state =
      if state.paused? do
        state
      else
        state
        |> Map.update!(:tick, &(&1 + 1))
        |> expire_messages()
      end

    broadcast_snapshot(state)
    schedule_tick(state.tick_interval_ms)

    {:noreply, state}
  end

  @impl true
  def handle_call(:toggle_pause, _from, state) do
    state = %{state | paused?: !state.paused?}
    broadcast_snapshot(state)
    {:reply, state.paused?, state}
  end

  @impl true
  def handle_call(:faster, _from, state) do
    tick_interval_ms = max(state.tick_interval_ms - @tick_step, @min_tick_rate)
    state = %{state | tick_interval_ms: tick_interval_ms}
    broadcast_snapshot(state)
    {:reply, tick_interval_ms, state}
  end

  @impl true
  def handle_call(:slower, _from, state) do
    tick_interval_ms = min(state.tick_interval_ms + @tick_step, @max_tick_rate)
    state = %{state | tick_interval_ms: tick_interval_ms}
    broadcast_snapshot(state)
    {:reply, tick_interval_ms, state}
  end

  @impl true
  def handle_call(:toggle_partition, _from, state) do
    state = %{state | partitioned?: !state.partitioned?}
    broadcast_snapshot(state)
    {:reply, state.partitioned?, state}
  end

  @impl true
  def handle_call(:spawn_citizen, _from, state) do
    id = state.next_citizen_id
    {x, y} = random_position()

    {:ok, _pid} =
      NatureWorld.CitizenSupervisor.start_citizen(%{
        id: id,
        x: x,
        y: y,
        node: node_for(id)
      })

    state =
      %{
        state
        | citizen_ids: [id | state.citizen_ids],
          next_citizen_id: id + 1,
          spawn_count: state.spawn_count + 1
      }

    broadcast_snapshot(state)

    {:reply, {:ok, id}, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, snapshot(state), state}
  end

  defp snapshot(state) do
    citizens = current_citizens(state)

    %{
      tick: state.tick,
      citizens: citizens,
      messages: state.messages,
      crashed_citizen_ids: MapSet.to_list(state.crashed_ids),
      paused?: state.paused?,
      tick_interval_ms: state.tick_interval_ms,
      telemetry: %{
        citizens_total: length(citizens),
        citizens_spawned: state.spawn_count,
        messages_seen: state.message_count,
        crashes_seen: state.crash_count,
        in_flight_messages: length(state.messages),
        tick_interval_ms: state.tick_interval_ms,
        paused?: state.paused?
      },
      cluster: cluster_snapshot(citizens, state.messages, state.partitioned?),
      supervisor: NatureWorld.CitizenSupervisor.stats()
    }
  end

  defp schedule_tick(interval_ms) do
    Process.send_after(self(), :tick, interval_ms)
  end

  defp spawn_citizens(count, next_id) do
    positions = random_positions(count, [])

    ids =
      for {{x, y}, id} <- Enum.zip(positions, next_id..(next_id + count - 1)) do
        {:ok, _pid} =
          NatureWorld.CitizenSupervisor.start_citizen(%{
            id: id,
            x: x,
            y: y,
            node: node_for(id)
          })

        id
      end

    {ids, next_id + count}
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

  defp current_citizens(state) do
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
  end

  defp cluster_snapshot(citizens, messages, partitioned?) do
    {local_count, remote_count} =
      Enum.reduce(citizens, {0, 0}, fn citizen, {local_acc, remote_acc} ->
        case citizen.node do
          :remote -> {local_acc, remote_acc + 1}
          _ -> {local_acc + 1, remote_acc}
        end
      end)

    cross_node_messages =
      Enum.count(messages, fn message ->
        node_for(message.from) != node_for(message.to)
      end)

    %{
      partitioned?: partitioned?,
      link_status: if(partitioned?, do: :partitioned, else: :connected),
      local: %{name: "Local node", count: local_count},
      remote: %{name: "Remote node", count: remote_count},
      cross_node_messages: cross_node_messages
    }
  end

  defp node_for(id) do
    if rem(id, 2) == 0, do: :remote, else: :local
  end

  defp random_position do
    positions =
      NatureWorld.CitizenSupervisor.positions()
      |> Enum.map(fn {_id, x, y} -> {x, y} end)

    random_position(positions)
  end

  defp random_position(existing_positions) do
    position = {
      Enum.random(40..860),
      Enum.random(40..660)
    }

    if valid_position?(position, existing_positions) do
      position
    else
      random_position(existing_positions)
    end
  end
end
