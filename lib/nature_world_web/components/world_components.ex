defmodule NatureWorldWeb.WorldComponents do
  use Phoenix.Component

  attr :citizen, :map, required: true
  attr :selected, :boolean, default: false
  attr :highlighted, :boolean, default: false

  def citizen(assigns) do
    depth =
      rem(assigns.citizen.id, 3)

    assigns =
      assign(assigns, :depth, depth)

    ~H"""
    <div
      class="absolute"
      style={"left: #{Float.round(@citizen.x / 880 * 100, 2)}%; top: #{Float.round(@citizen.y / 680 * 100, 2)}%;"}
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
        id={"citizen-#{@citizen.id}-#{@citizen.generation}"}
        phx-click="select-citizen"
        phx-value-id={@citizen.id}
        class={[
          "rounded-full transition-all duration-300 cursor-pointer citizen",
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
            ],
          @highlighted && "citizen-message-highlight",
          @citizen.generation > 1 && "citizen-restarted"
        ]}
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
        |> assign(
          :distance,
          :math.sqrt(:math.pow(to.x - from.x, 2) + :math.pow(to.y - from.y, 2))
        )
        |> assign(
          :angle,
          :math.atan2(to.y - from.y, to.x - from.x) * 180 / :math.pi()
        )

      ~H"""
      <%= if @render do %>
        <div
          id={"message-#{@message.id}"}
          class="absolute inset-0 pointer-events-none z-[999]"
        >
          <!-- Message line -->
          <div
            class="absolute h-px bg-emerald-300/70 shadow-[0_0_12px_rgba(110,231,183,0.8)]"
            style={
              "left: #{@from.x / 880 * 100}%;
               top: #{@from.y / 680 * 100}%;
               width: #{@distance / 880 * 100}%;
               transform: rotate(#{@angle}deg);
               transform-origin: left center;"
            }
          >
          </div>
          
      <!-- Animated arrowhead -->
          <div
            id={"message-arrow-#{@message.id}"}
            phx-hook="MessageParticle"
            phx-update="ignore"
            data-from-x={@from.x}
            data-from-y={@from.y}
            data-to-x={@to.x}
            data-to-y={@to.y}
            class="
              absolute
              w-0
              h-0
              border-y-[4px]
              border-y-transparent
              border-l-[8px]
              border-l-emerald-200
              drop-shadow-[0_0_8px_rgba(110,231,183,0.95)]
            "
            style={
              "left: #{@from.x / 880 * 100}%;
               top: #{@from.y / 680 * 100}%;
               transform: translate(-50%, -50%) rotate(#{@angle}deg);
               transform-origin: center;"
            }
          >
          </div>
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
      <%= if @citizen do %>
        <h2 class="text-2xl font-bold">
          {"Citizen #{@citizen.id}"}
        </h2>

        <div class="space-y-5">
          <div class="flex justify-between">
            <span class="text-zinc-400">State</span>

            <span class={[
              "font-semibold",
              @citizen.state == :idle && "text-emerald-400",
              @citizen.state == :excited && "text-yellow-300"
            ]}>
              {@citizen.state}
            </span>
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">Running</span>
            <span>
              <%= if @citizen.pid && Process.alive?(@citizen.pid) do %>
                yes
              <% else %>
                restarting
              <% end %>
            </span>
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">PID</span>
            <span class="font-mono text-xs">{inspect(@citizen.pid)}</span>
          </div>

          <div class="flex justify-between">
            <span class="text-zinc-400">Restarts</span>
            <span>{@citizen.generation - 1}</span>
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
      <% else %>
        <h2 class="text-2xl font-bold">
          No Citizen Selected
        </h2>
      <% end %>
    </div>
    """
  end
end
