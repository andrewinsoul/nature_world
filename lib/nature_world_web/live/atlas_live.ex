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
       world: NatureWorld.Simulation.state()
     )}
  end

  @impl true
  def handle_info({:tick, state}, socket) do
    {:noreply, assign(socket, world: state)}
  end
end
