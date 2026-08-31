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
    <button
      type="button"
      id={"citizen-#{@citizen.id}-#{@citizen.generation}"}
      phx-click="select-citizen"
      phx-value-id={@citizen.id}
      aria-label={"Select citizen #{@citizen.id}"}
      class="absolute h-14 w-14 cursor-pointer border-0 bg-transparent p-0 text-left"
      style={"left: #{Float.round(@citizen.x / 880 * 100, 2)}%; top: #{Float.round(@citizen.y / 680 * 100, 2)}%;"}
    >
      <div class={[
        "absolute inset-0 rounded-full blur-xl transition-opacity duration-500 citizen-glow pointer-events-none",
        @citizen.state == :excited &&
          "bg-yellow-400/35 scale-125",
        @citizen.state != :excited &&
          "bg-emerald-400/10"
      ]}>
      </div>
      <div
        class={[
          "absolute left-5 top-5 rounded-full transition-all duration-300 citizen pointer-events-none",
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
    </button>
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
      ~H"""
      """
    else
      assigns =
        assigns
        |> assign(:from, from)
        |> assign(:to, to)
        |> assign(
          :angle,
          :math.atan2(to.y - from.y, to.x - from.x) * 180 / :math.pi()
        )

      ~H"""
      <div
        id={"message-#{@message.id}"}
        class="absolute inset-0 pointer-events-none z-[999]"
        phx-hook="MessageParticle"
        phx-update="ignore"
        data-from-x={@from.x}
        data-from-y={@from.y}
        data-to-x={@to.x}
        data-to-y={@to.y}
      >
        <svg
          class="absolute inset-0 h-full w-full overflow-visible"
          viewBox="0 0 900 700"
          preserveAspectRatio="none"
        >
          <!-- Message path -->
          <line
            x1={@from.x}
            y1={@from.y}
            x2={@to.x}
            y2={@to.y}
            stroke="rgba(110, 231, 183, 0.55)"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-dasharray="5 7"
            filter={"url(#message-glow-#{@message.id})"}
          />
          
      <!-- Glow definition -->
          <defs>
            <filter
              id={"message-glow-#{@message.id}"}
              x="-100%"
              y="-100%"
              width="300%"
              height="300%"
            >
              <feGaussianBlur
                stdDeviation="3"
                result="blur"
              />

              <feMerge>
                <feMergeNode in="blur" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>
          
      <!-- Animated arrowhead -->
          <g
            id={"message-arrow-#{@message.id}"}
            class="message-arrow"
            transform={"translate(#{@from.x} #{@from.y}) rotate(#{@angle})"}
          >
            <path
              d="M -10 -6 L 4 0 L -10 6 L -6 0 Z"
              fill="#a7f3d0"
              filter={"url(#message-glow-#{@message.id})"}
            />
          </g>
        </svg>
      </div>
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
