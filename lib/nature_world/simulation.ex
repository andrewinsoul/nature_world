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
    state = %{
      tick: 0,
      citizens: spawn_citizens()
    }

    schedule_tick()

    {:ok, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    snapshot = %{
      tick: state.tick,
      citizens: Enum.map(state.citizens, &NatureWorld.Citizen.state/1)
    }

    {:reply, snapshot, state}
  end

  @impl true
  def handle_info(:tick, state) do
    state =
      Map.update!(state, :tick, &(&1 + 1))

    snapshot = %{
      tick: state.tick,
      citizens: Enum.map(state.citizens, &NatureWorld.Citizen.state/1)
    }

    Phoenix.PubSub.broadcast(
      NatureWorld.PubSub,
      "simulation",
      {:tick, snapshot}
    )

    schedule_tick()

    {:noreply, state}
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
end
