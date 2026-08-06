defmodule NatureWorldWeb.WorldComponents do
  use Phoenix.Component

  attr :citizen, :map, required: true
  attr :selected, :boolean, default: false

  def citizen(assigns) do
    depth =
      rem(assigns.citizen.id, 3)

    assigns =
      assign(assigns, :depth, depth)

    ~H"""
    <div
      class="absolute"
      style={"left: #{@citizen.x}px; top: #{@citizen.y}px;"}
    >
      <div class={[
        "absolute -left-5 -top-5 h-14 w-14 rounded-full blur-xl transition-all duration-500 citizen-glow",
        @citizen.state == :excited &&
          "bg-yellow-400/35 scale-125",
        @citizen.state != :excited &&
          "bg-emerald-400/10"
      ]}>
      </div>
      <div
        phx-click="select-citizen"
        phx-value-id={@citizen.id}
        class={[
          "absolute rounded-full transition-all duration-300 cursor-pointer citizen",
          @depth == 0 && "opacity-100",
          @depth == 1 && "opacity-75",
          @depth == 2 && "opacity-50",
          @citizen.state == :excited &&
            [
              "w-6 h-6",
              "bg-yellow-300",
              "shadow-[0_0_30px_rgba(253,224,71,0.95)]",
              "ring-4 ring-yellow-400/50"
            ],
          @citizen.state != :excited &&
            [
              "w-4 h-4",
              "bg-emerald-400"
            ],
          @selected &&
            [
              "ring-4",
              "ring-sky-400",
              "scale-125"
            ]
        ]}
        style={"left: #{@citizen.x}px; top: #{@citizen.y}px;"}
      >
      </div>
    </div>
    """
  end

  attr :message, :map, required: true
  attr :citizens, :list, required: true

  def message(assigns) do
    from =
      Enum.find(assigns.citizens, &(&1.id == assigns.message.from))

    to =
      Enum.find(assigns.citizens, &(&1.id == assigns.message.to))

    if from == nil or to == nil do
      assigns = assign(assigns, :render, false)

      ~H"""
      """
    else
      assigns =
        assigns
        |> assign(:render, true)
        |> assign(:from, from)
        |> assign(:to, to)

      ~H"""
      <%= if @render do %>
        <div
          id={"message-#{@message.id}"}
          phx-hook="MessageParticle"
          data-from-x={@from.x}
          data-from-y={@from.y}
          data-to-x={@to.x}
          data-to-y={@to.y}
          class="
      absolute
      w-2
      h-2
      rounded-full
      bg-emerald-300
      shadow-[0_0_18px_rgba(110,231,183,0.95)]
      z-[999]
      "
        >
        </div>
      <% end %>
      """
    end
  end

  attr :citizen, :map, default: nil

  def inspector(assigns) do
    ~H"""
    <div class="
      fixed
      top-10
      right-10
      w-80
      rounded-2xl
      bg-zinc-900/90
      backdrop-blur-xl
      border
      border-zinc-700
      p-6
      shadow-2xl
    ">
      <h2 class="text-2xl font-bold">
        {"Citizen #{@citizen.id}"}
      </h2>

      <div class="space-y-5">
        <div class="flex justify-between">
          <span class="text-zinc-400">Status</span>

          <span class={[
            "font-semibold",
            @citizen.state == :idle && "text-emerald-400",
            @citizen.state == :excited && "text-yellow-300"
          ]}>
            {@citizen.state}
          </span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Energy</span>
          <span>{@citizen.energy}%</span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Position</span>
          <span>
            ({@citizen.x}, {@citizen.y})
          </span>
        </div>
      </div>
    </div>
    """
  end
end
