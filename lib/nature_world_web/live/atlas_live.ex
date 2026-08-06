defmodule NatureWorldWeb.AtlasLive do
  use NatureWorldWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        NatureWorld.PubSub,
        "simulation"
      )
    end

    {:ok,
     assign(socket,
       world: NatureWorld.Simulation.state(),
       last_event: nil,
       selected_citizen_id: nil
     )}
  end

  @impl true
  def handle_event("select-citizen", %{"id" => id}, socket) do
    # citizen =
    #   socket.assigns.world.citizens
    #   |> Enum.find(&(&1.id == String.to_integer(id)))

    {:noreply,
     assign(socket,
       selected_citizen_id: String.to_integer(id)
     )}
  end

  @impl true
  def handle_info({:tick, state}, socket) do
    {:noreply, assign(socket, world: state)}
  end
end
