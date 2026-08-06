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
      citizens: spawn_citizens(),
      messages: []
    }

    schedule_tick()

    {:ok, state}
  end

  @impl true
  def handle_info({:message_sent, message}, state) do
    state = %{
      state
      | messages: [message | state.messages]
    }

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state =
      state
      |> Map.update!(:tick, &(&1 + 1))
      |> expire_messages()

    Phoenix.PubSub.broadcast(
      NatureWorld.PubSub,
      "simulation",
      {:tick, snapshot(state)}
    )

    schedule_tick()

    {:noreply, state}
  end

  defp snapshot(state) do
    %{
      tick: state.tick,
      citizens: Enum.map(state.citizens, &NatureWorld.Citizen.state/1),
      messages: state.messages
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
    for id <- 1..50 do
      {:ok, pid} =
        NatureWorld.CitizenSupervisor.start_citizen(%{
          id: id,
          x: Enum.random(20..880),
          y: Enum.random(20..680)
        })

      pid
    end
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
