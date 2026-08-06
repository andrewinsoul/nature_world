defmodule NatureWorldWeb.DashboardComponents do
  use Phoenix.Component

  attr :world, :map, required: true
  attr :citizen, :any, default: nil

  def dashboard(assigns) do
    ~H"""
    <div class="rounded-3xl border border-white/5 bg-white/5 p-6 backdrop-blur-xl">
      <div class="flex items-center gap-2">
        <div class="h-2.5 w-2.5 rounded-full bg-emerald-400"></div>

        <span class="text-xs uppercase tracking-[0.3em] text-zinc-400">
          System
        </span>
      </div>

      <div class="mt-8 space-y-4">
        <div class="flex justify-between">
          <span class="text-zinc-400">Processes</span>
          <span>{length(@world.citizens)}</span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Messages</span>
          <span>{length(@world.messages)}</span>
        </div>
      </div>

      <%= if @citizen do %>
        <hr class="my-6 border-white/5" />

        <div class="mb-4 text-xs uppercase tracking-[0.3em] text-zinc-400">
          Selected Citizen
        </div>

        <div class="space-y-4">
          <div class="text-2xl font-bold">
            Citizen {@citizen.id}
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">State</span>
            <span>{@citizen.state}</span>
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">Energy</span>
            <span>{@citizen.energy}%</span>
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">Position</span>
            <span>({@citizen.x}, {@citizen.y})</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
