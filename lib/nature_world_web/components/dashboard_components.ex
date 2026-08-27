defmodule NatureWorldWeb.DashboardComponents do
  use Phoenix.Component

  import NatureWorldWeb.CoreComponents

  attr :world, :map, required: true
  attr :citizen, :any, default: nil
  attr :message_form, :any, default: nil
  attr :recipient_options, :list, default: []
  attr :selected_citizen_id, :any, default: nil
  attr :education_event, :map, default: nil
  attr :tutorial, :map, default: nil
  attr :beam_lab_topic, :atom, default: :message_passing

  def dashboard(assigns) do
    ~H"""
    <div class="rounded-3xl border border-white/5 bg-white/5 p-5 backdrop-blur-xl">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-2">
          <div class="h-2.5 w-2.5 rounded-full bg-emerald-400"></div>

          <span class="text-xs uppercase tracking-[0.3em] text-zinc-400">
            System
          </span>
        </div>

        <div class="text-xs text-zinc-500">
          BEAM processes in motion
        </div>
      </div>

      <div class="mt-4 grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
        <div class="flex justify-between">
          <span class="text-zinc-400">Processes</span>
          <span>{length(@world.citizens)}</span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Messages</span>
          <span>{length(@world.messages)}</span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Running</span>
          <span>{@world.supervisor.running_citizens}</span>
        </div>

        <div class="flex justify-between">
          <span class="text-zinc-400">Restarts</span>
          <span>{@world.supervisor.restart_count}</span>
        </div>
      </div>

      <%= if @tutorial do %>
        <div
          id="guided-tutorial"
          data-step={@tutorial.step}
          class={[
            "mt-5 rounded-2xl border p-4",
            @tutorial.step == :complete &&
              "border-emerald-400/20 bg-emerald-400/10",
            @tutorial.step != :complete &&
              "border-sky-400/20 bg-sky-400/10"
          ]}
        >
          <div class="flex items-center justify-between gap-3">
            <div>
              <div class="text-[11px] uppercase tracking-[0.35em] text-sky-300/80">
                Guided Tutorial
              </div>

              <div class="mt-1 text-sm text-zinc-400">
                Step {@tutorial.step_index} of {@tutorial.total_steps}
              </div>
            </div>

            <div class="h-2.5 w-2.5 rounded-full bg-sky-300 shadow-[0_0_18px_rgba(125,211,252,0.9)]"></div>
          </div>

          <div class="mt-3 text-lg font-semibold text-white">
            {@tutorial.title}
          </div>

          <p class="mt-2 text-sm leading-6 text-zinc-200">
            {@tutorial.body}
          </p>

          <p class="mt-3 text-sm text-sky-200/90">
            {@tutorial.guidance}
          </p>

          <div class="mt-4 flex flex-wrap gap-2">
            <button
              id="guided-tutorial-next"
              type="button"
              phx-click={@tutorial.action_event}
              class={[
                "btn btn-sm",
                @tutorial.step == :complete && "btn-success",
                @tutorial.step != :complete && "btn-info"
              ]}
            >
              {@tutorial.action_label}
            </button>

            <%= if @tutorial.secondary_label && @tutorial.secondary_event do %>
              <button
                id="guided-tutorial-skip"
                type="button"
                phx-click={@tutorial.secondary_event}
                class="btn btn-sm btn-ghost text-zinc-200"
              >
                {@tutorial.secondary_label}
              </button>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @citizen do %>
        <div class="mt-5 rounded-2xl border border-white/5 bg-black/20 p-4">
          <div class="mb-3 text-xs uppercase tracking-[0.3em] text-zinc-400">
            Selected Citizen
          </div>

          <div class="text-xl font-semibold">
            Citizen {@citizen.id}
          </div>

          <div class="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-zinc-400">State</span>
              <span>{@citizen.state}</span>
            </div>

            <div class="flex justify-between">
              <span class="text-zinc-400">Restarts</span>
              <span>{@citizen.generation - 1}</span>
            </div>

            <div class="flex justify-between">
              <span class="text-zinc-400">Running</span>
              <span class={[
                "font-semibold",
                @citizen.pid && Process.alive?(@citizen.pid) && "text-emerald-400",
                !(@citizen.pid && Process.alive?(@citizen.pid)) && "text-zinc-400"
              ]}>
                <%= if @citizen.pid && Process.alive?(@citizen.pid) do %>
                  alive
                <% else %>
                  restarting
                <% end %>
              </span>
            </div>

            <div class="flex justify-between">
              <span class="text-zinc-400">Energy</span>
              <span>{@citizen.energy}%</span>
            </div>
          </div>

          <div class="mt-3 text-xs font-mono text-zinc-500">
            PID {inspect(@citizen.pid)}
          </div>

          <div class="mt-4 space-y-3">
            <%= if @recipient_options != [] do %>
              <.form
                for={@message_form}
                id="message-playground-form"
                phx-change="set-recipient"
                phx-submit="send-message"
                class="space-y-2"
              >
                <.input
                  field={@message_form[:recipient_id]}
                  type="select"
                  label="Send Message"
                  options={@recipient_options}
                  prompt="Choose a recipient"
                />

                <div class="grid grid-cols-2 gap-2">
                  <button
                    type="submit"
                    class="btn btn-sm btn-success"
                    disabled={@selected_citizen_id == nil}
                  >
                    Send
                  </button>

                  <button
                    type="button"
                    phx-click="crash-selected"
                    class="btn btn-sm btn-error"
                    disabled={@selected_citizen_id == nil}
                  >
                    Crash
                  </button>
                </div>
              </.form>
            <% else %>
              <p class="text-sm text-zinc-500">
                Select a citizen to enable messaging.
              </p>
            <% end %>

            <button
              type="button"
              phx-click="crash-random"
              class="btn btn-sm btn-outline btn-error w-full"
              disabled={@world.citizens == []}
            >
              Crash Random Citizen
            </button>
          </div>
        </div>
      <% end %>

      <%= if @education_event do %>
        <div
          id="education-event"
          class="mt-4 rounded-2xl border border-emerald-400/20 bg-emerald-400/5 p-4"
        >
          <div class="text-[11px] uppercase tracking-[0.35em] text-emerald-300/80">
            <%= case @education_event.kind do %>
              <% :message -> %>
                Message Passing
              <% :crash -> %>
                Supervision
            <% end %>
          </div>

          <div class="mt-2 text-sm text-zinc-200">
            <%= case @education_event.kind do %>
              <% :message -> %>
                Citizen {@education_event.sender} sent a message to Citizen {@education_event.recipient}. Processes communicate by sending messages.
              <% :crash -> %>
                Citizen {@education_event.citizen} failed. Its supervisor started a new process while the rest of the system kept running.
            <% end %>
          </div>
        </div>
      <% end %>

      <div class="mt-4 rounded-2xl border border-white/5 bg-black/10 px-4 py-3 text-xs text-zinc-400">
        <div class="flex flex-wrap gap-4">
          <span>● Process</span>
          <span>──► Message</span>
          <span>↻ Supervision</span>
        </div>

        <p class="mt-2 text-zinc-500">
          Processes communicate through messages. Supervisors restart failed processes.
        </p>
      </div>
    </div>
    """
  end
end
