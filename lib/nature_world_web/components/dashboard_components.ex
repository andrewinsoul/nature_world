defmodule NatureWorldWeb.DashboardComponents do
  use Phoenix.Component

  # import NatureWorldWeb.CoreComponents

  attr :world, :map, required: true
  attr :citizen, :any, default: nil
  attr :education_event, :map, default: nil
  attr :beam_lab_topic, :atom, default: :message_passing

  def dashboard(assigns) do
    ~H"""
    <% cluster = @world.cluster %>
    <% paused? = Map.get(@world, :paused?) %>
    <% partitioned? = Map.get(cluster, :partitioned?) %>

    <div class="rounded-[32px] border border-white/5 bg-white/5 p-6 backdrop-blur-xl shadow-[0_30px_80px_rgba(0,0,0,0.25)]">
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

      <div class="mt-4 flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.2em]">
        <span class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-zinc-300">
          <%= if paused? do %>
            paused
          <% else %>
            running
          <% end %>
        </span>

        <span class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-zinc-300">
          tick {@world.tick_interval_ms}ms
        </span>

        <span class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-zinc-300">
          spawned {@world.telemetry.citizens_spawned}
        </span>

        <span class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-zinc-300">
          crashes {@world.telemetry.crashes_seen}
        </span>

        <span class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-zinc-300">
          cross-node {@world.cluster.cross_node_messages}
        </span>
      </div>

      <%= if @education_event do %>
        <div
          id="education-event"
          class="mt-6 rounded-2xl border border-emerald-400/20 bg-emerald-400/5 p-4"
        >
          <div class="text-[11px] uppercase tracking-[0.35em] text-emerald-300/80">
            <%= case @education_event.kind do %>
              <% :message -> %>
                Message Passing
              <% :crash -> %>
                Supervision
              <% :spawn -> %>
                Process Spawning
              <% :pause -> %>
                Time Controls
              <% :partition -> %>
                Distributed Nodes
              <% :tutorial -> %>
                Interactive Tutorial
            <% end %>
          </div>

          <div class="mt-2 text-sm text-zinc-200">
            <%= case @education_event.kind do %>
              <% :message -> %>
                Citizen {@education_event.sender} sent a message to Citizen {@education_event.recipient}. Processes communicate by sending messages.
              <% :crash -> %>
                Citizen {@education_event.citizen} failed. Its supervisor started a new process while the rest of the system kept running.
              <% :spawn -> %>
                Citizen {@education_event.citizen} joined the world. New processes appear instantly and are supervised like the rest.
              <% :pause -> %>
                The simulation clock was {@education_event.action}. Time controls let you slow down, speed up, or pause the runtime.
              <% :partition -> %>
                The world is now {@education_event.status}. This simulates distributed nodes and makes cluster boundaries visible.
              <% :tutorial -> %>
                The tutorial restarted from the beginning so you can walk through the BEAM concepts again.
            <% end %>
          </div>
        </div>
      <% end %>

      <div class="mt-6 grid gap-6 lg:grid-cols-2">
        <div class="rounded-[28px] border border-white/5 bg-black/20 p-5">
          <div class="flex items-center justify-between gap-4">
            <div>
              <div class="text-[11px] uppercase tracking-[0.35em] text-zinc-400">
                Processes
              </div>

              <div class="mt-1 text-lg font-semibold text-white">
                Live citizen processes
              </div>
            </div>

            <div class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] uppercase tracking-[0.25em] text-zinc-300">
              {@world.supervisor.running_citizens} running
            </div>
          </div>

          <div class="mt-3 grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-zinc-400">Total</span>
              <span>{length(@world.citizens)}</span>
            </div>

            <div class="flex justify-between">
              <span class="text-zinc-400">Restarts</span>
              <span>{@world.supervisor.restart_count}</span>
            </div>
          </div>

          <p class="mt-4 text-sm leading-6 text-zinc-300">
            These are the BEAM processes your world is currently supervising. On desktop, this list stays next to the citizen controls so new developers can compare the process tree with the actions they are taking.
          </p>

          <div class="mt-4 grid gap-2 sm:grid-cols-2">
            <button
              type="button"
              phx-click="simulation-toggle-pause"
              class="btn btn-sm btn-outline btn-info w-full"
            >
              <%= if paused? do %>
                Resume Clock
              <% else %>
                Pause Clock
              <% end %>
            </button>

            <button
              type="button"
              phx-click="simulation-faster"
              class="btn btn-sm btn-outline btn-info w-full"
            >
              Speed Up
            </button>

            <button
              type="button"
              phx-click="simulation-slower"
              class="btn btn-sm btn-outline btn-info w-full"
            >
              Slow Down
            </button>

            <button
              type="button"
              phx-click="spawn-citizen"
              class="btn btn-sm btn-success w-full"
            >
              Spawn Citizen
            </button>

            <button
              type="button"
              phx-click="tutorial-replay"
              class="btn btn-sm btn-ghost w-full text-sky-100 hover:bg-sky-400/10"
            >
              Replay Tutorial
            </button>

            <button
              type="button"
              phx-click="toggle-partition"
              class="btn btn-sm btn-outline btn-warning w-full"
            >
              <%= if partitioned? do %>
                Reconnect Nodes
              <% else %>
                Partition Nodes
              <% end %>
            </button>
          </div>

          <%= if @world.citizens == [] do %>
            <div class="mt-4 rounded-2xl border border-dashed border-white/10 bg-white/5 px-4 py-4 text-sm text-zinc-500">
              No active citizen processes are available right now.
            </div>
          <% else %>
            <div class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
              <%= for citizen <- @world.citizens do %>
                <div class={[
                  "rounded-2xl border px-4 py-3 text-sm transition-colors",
                  @citizen && @citizen.id == citizen.id &&
                    "border-sky-400/40 bg-sky-400/10 text-white",
                  !(@citizen && @citizen.id == citizen.id) &&
                    "border-white/5 bg-white/5 text-zinc-300"
                ]}>
                  <div class="flex items-center justify-between gap-3">
                    <div class="font-medium">
                      Citizen {citizen.id}
                    </div>

                    <div class="text-[11px] uppercase tracking-[0.25em] text-zinc-500">
                      gen {citizen.generation}
                    </div>
                  </div>

                  <div class="mt-2 flex flex-wrap gap-2 text-[11px] text-zinc-400">
                    <span class="rounded-full border border-white/10 bg-black/20 px-2 py-1">
                      {citizen.state}
                    </span>

                    <span class="rounded-full border border-white/10 bg-black/20 px-2 py-1">
                      mailbox {length(citizen_mailbox(citizen))}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @world.crashed_citizen_ids != [] do %>
            <div class="mt-4 rounded-2xl border border-amber-400/20 bg-amber-400/10 p-3">
              <div class="text-xs uppercase tracking-[0.3em] text-amber-200/80">
                Recently failed children
              </div>

              <div class="mt-2 flex flex-wrap gap-2 text-xs text-amber-50">
                <%= for id <- @world.crashed_citizen_ids do %>
                  <span class="rounded-full border border-amber-300/20 bg-amber-300/10 px-2 py-1">
                    Citizen {id}
                  </span>
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="mt-4 rounded-2xl border border-emerald-400/15 bg-emerald-400/10 p-3 text-sm text-emerald-50">
              No currently failed citizens. The supervisor tree is healthy.
            </div>
          <% end %>
        </div>

        <div class="rounded-[28px] border border-white/5 bg-black/20 p-5">
          <div class="flex items-center justify-between gap-4">
            <div>
              <div class="text-[11px] uppercase tracking-[0.35em] text-zinc-400">
                BEAM Lab
              </div>

              <div class="mt-1 text-lg font-semibold text-white">
                {beam_lab_title(@beam_lab_topic)}
              </div>
            </div>

            <div class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] uppercase tracking-[0.25em] text-zinc-300">
              {beam_lab_label(@beam_lab_topic)}
            </div>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-2">
            <%= for topic <- beam_lab_topics() do %>
              <button
                type="button"
                phx-click="select-lab-topic"
                phx-value-topic={topic.key}
                class={[
                  "rounded-xl border px-3 py-2 text-left text-sm transition-all duration-200",
                  @beam_lab_topic == topic.key &&
                    "border-sky-400/40 bg-sky-400/15 text-white shadow-[0_0_24px_rgba(56,189,248,0.15)]",
                  @beam_lab_topic != topic.key &&
                    "border-white/5 bg-white/5 text-zinc-300 hover:border-white/10 hover:bg-white/10"
                ]}
              >
                <div class="font-medium">
                  {topic.label}
                </div>

                <div class="mt-1 text-xs text-zinc-400">
                  {topic.short_description}
                </div>
              </button>
            <% end %>
          </div>

          <div class="mt-4 rounded-2xl border border-white/5 bg-black/30 p-4">
            <p class="text-sm leading-6 text-zinc-200">
              {beam_lab_description(@beam_lab_topic)}
            </p>

            <p class="mt-2 text-xs uppercase tracking-[0.3em] text-sky-200/80">
              {beam_lab_prompt(@beam_lab_topic)}
            </p>
          </div>

          <div class="mt-4 rounded-2xl border border-white/5 bg-black/20 p-4">
            <div class="flex items-center justify-between gap-3">
              <div>
                <div class="text-[11px] uppercase tracking-[0.35em] text-zinc-400">
                  Cluster Snapshot
                </div>

                <div class="mt-1 text-sm text-zinc-300">
                  Local and remote citizens share the same runtime model.
                </div>
              </div>

              <div class={[
                "rounded-full px-3 py-1 text-[11px] uppercase tracking-[0.25em]",
                partitioned? &&
                  "border border-amber-400/20 bg-amber-400/10 text-amber-100",
                !partitioned? &&
                  "border border-emerald-400/20 bg-emerald-400/10 text-emerald-100"
              ]}>
                <%= if partitioned? do %>
                  partitioned
                <% else %>
                  connected
                <% end %>
              </div>
            </div>

            <div class="mt-4 grid grid-cols-3 gap-2 text-sm">
              <div class="rounded-xl border border-white/5 bg-white/5 px-3 py-2">
                <div class="text-[11px] uppercase tracking-[0.3em] text-zinc-500">
                  Local
                </div>
                <div class="mt-1 font-semibold text-white">
                  {@world.cluster.local.count}
                </div>
              </div>

              <div class="rounded-xl border border-white/5 bg-white/5 px-3 py-2">
                <div class="text-[11px] uppercase tracking-[0.3em] text-zinc-500">
                  Remote
                </div>
                <div class="mt-1 font-semibold text-white">
                  {@world.cluster.remote.count}
                </div>
              </div>

              <div class="rounded-xl border border-white/5 bg-white/5 px-3 py-2">
                <div class="text-[11px] uppercase tracking-[0.3em] text-zinc-500">
                  Cross-node
                </div>
                <div class="mt-1 font-semibold text-white">
                  {@world.cluster.cross_node_messages}
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>

      <div class="mt-6 grid gap-6 lg:grid-cols-2">
        <div class="rounded-[28px] border border-white/5 bg-black/20 p-5">
          <div class="flex items-center justify-between gap-4">
            <div>
              <div class="text-[11px] uppercase tracking-[0.35em] text-zinc-400">
                Mailbox
              </div>

              <div class="mt-1 text-sm text-zinc-300">
                Recent messages received by the selected process
              </div>
            </div>

            <%= if @citizen do %>
              <div class="rounded-full border border-sky-400/20 bg-sky-400/10 px-3 py-1 text-xs font-semibold text-sky-100">
                {length(citizen_mailbox(@citizen))} queued
              </div>
            <% else %>
              <div class="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs font-semibold text-zinc-300">
                Select a citizen
              </div>
            <% end %>
          </div>

          <%= if @citizen do %>
            <% citizen_mailbox = citizen_mailbox(@citizen) %>
            <%= if citizen_mailbox == [] do %>
              <div class="mt-3 rounded-xl border border-dashed border-white/10 bg-white/5 px-4 py-3 text-sm text-zinc-500">
                The mailbox is empty right now. Send a message to watch the queue appear.
              </div>
            <% else %>
              <div class="mt-3 grid gap-2 md:grid-cols-2">
                <%= for message <- Enum.take(citizen_mailbox, 6) do %>
                  <div class="rounded-xl border border-white/5 bg-white/5 px-4 py-3">
                    <div class="flex items-center justify-between gap-3 text-xs text-zinc-400">
                      <span>From Citizen {message.from}</span>
                      <span>{mailbox_age_label(message.started_at)}</span>
                    </div>

                    <div class="mt-2 text-sm text-zinc-200">
                      Waiting in mailbox for Citizen {@citizen.id}
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% else %>
            <div class="mt-3 rounded-xl border border-dashed border-white/10 bg-white/5 px-4 py-3 text-sm text-zinc-500">
              Select a citizen to inspect its mailbox.
            </div>
          <% end %>
        </div>

        <div class="rounded-[28px] border border-white/5 bg-black/20 p-5">
          <div class="flex items-center justify-between gap-4">
            <div>
              <div class="text-[11px] uppercase tracking-[0.35em] text-zinc-400">
                Supervision Tree
              </div>

              <div class="mt-1 text-sm text-zinc-300">
                NatureWorld.Supervisor keeps the runtime alive
              </div>
            </div>

            <div class="text-xs text-zinc-500">
              {@world.supervisor.running_citizens} running, {@world.supervisor.restart_count} restarts
            </div>
          </div>

          <div class="mt-4 rounded-2xl border border-white/5 bg-black/30 p-4">
            <div class="rounded-xl border border-white/5 bg-white/5 p-3">
              <div class="text-sm font-semibold text-white">
                NatureWorld.Supervisor
              </div>

              <div class="mt-1 text-xs text-zinc-400">
                Application root supervisor
              </div>

              <div class="mt-3 grid gap-3 md:grid-cols-2">
                <div class="rounded-xl border border-white/5 bg-black/20 p-3">
                  <div class="text-sm font-medium text-white">
                    NatureWorld.Simulation
                  </div>

                  <div class="mt-1 text-xs text-zinc-400">
                    Owns the world snapshot, tick loop, and message lifecycle.
                  </div>

                  <div class="mt-3 flex flex-wrap gap-2 text-[11px] text-zinc-300">
                    <span class="rounded-full border border-white/10 bg-white/5 px-2 py-1">
                      tick: {@world.tick}
                    </span>

                    <span class="rounded-full border border-white/10 bg-white/5 px-2 py-1">
                      messages: {length(@world.messages)}
                    </span>
                  </div>
                </div>

                <div class="rounded-xl border border-white/5 bg-black/20 p-3">
                  <div class="text-sm font-medium text-white">
                    NatureWorld.CitizenSupervisor
                  </div>

                  <div class="mt-1 text-xs text-zinc-400">
                    DynamicSupervisor responsible for every citizen process.
                  </div>

                  <div class="mt-3 flex flex-wrap gap-2 text-[11px] text-zinc-300">
                    <span class="rounded-full border border-white/10 bg-white/5 px-2 py-1">
                      active: {@world.supervisor.running_citizens}
                    </span>

                    <span class="rounded-full border border-white/10 bg-white/5 px-2 py-1">
                      restarts: {@world.supervisor.restart_count}
                    </span>
                  </div>
                </div>
              </div>

              <div class="mt-4 rounded-xl border border-zinc-700/40 bg-black/20 p-3 text-sm text-zinc-300">
                The process list now lives in the top row so you can compare citizen state with the control panel side by side on desktop.
              </div>
            </div>
          </div>
        </div>
      </div>

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

  defp beam_lab_topics do
    [
      %{
        key: :message_passing,
        label: "Messages",
        short_description: "Watch asynchronous communication",
        title: "Message Passing"
      },
      %{
        key: :process_isolation,
        label: "Isolation",
        short_description: "Inspect one process at a time",
        title: "Process Isolation"
      },
      %{
        key: :distributed_nodes,
        label: "Distributed",
        short_description: "Simulate local and remote nodes",
        title: "Distributed Nodes"
      },
      %{
        key: :supervision,
        label: "Supervision",
        short_description: "See restarts recover the system",
        title: "Supervision"
      },
      %{
        key: :fault_tolerance,
        label: "Fault Tolerance",
        short_description: "Learn how the world survives failure",
        title: "Fault Tolerance"
      }
    ]
  end

  defp beam_lab_title(topic) do
    beam_lab_topic_data(topic).title
  end

  defp beam_lab_label(topic) do
    beam_lab_topic_data(topic).label
  end

  defp beam_lab_description(:message_passing) do
    "Every message is delivered asynchronously. The selected citizen receives work without blocking the sender, and the animated badges show when a message is in flight or waiting in a mailbox."
  end

  defp beam_lab_description(:process_isolation) do
    "Each citizen owns its own state, mailbox, and lifecycle. Selecting one process lets you inspect its local world without touching the rest of the system."
  end

  defp beam_lab_description(:distributed_nodes) do
    "The world is split across local and remote nodes. This does not need real network traffic to teach the concept: the stage and cluster summary make the split visible and let you toggle partitions."
  end

  defp beam_lab_description(:supervision) do
    "A supervisor watches over citizen processes and restarts them when they fail. The tree below shows the application root, the simulation layer, and all active children."
  end

  defp beam_lab_description(:fault_tolerance) do
    "Crashes are part of the story, not the end of it. The fault-tolerance view helps new Elixir developers see that the system can absorb failure and keep going."
  end

  defp beam_lab_description(_), do: beam_lab_description(:message_passing)

  defp beam_lab_prompt(:message_passing) do
    "Try sending a message from the selected citizen."
  end

  defp beam_lab_prompt(:process_isolation) do
    "Click different citizens and compare their private state."
  end

  defp beam_lab_prompt(:distributed_nodes) do
    "Toggle the partition control and watch the local and remote counts."
  end

  defp beam_lab_prompt(:supervision) do
    "Crash a citizen and watch the tree stay intact."
  end

  defp beam_lab_prompt(:fault_tolerance) do
    "Use crash selected or crash random to trigger controlled failure."
  end

  defp beam_lab_prompt(_), do: beam_lab_prompt(:message_passing)

  defp mailbox_age_label(started_at) do
    age_ms =
      System.monotonic_time()
      |> Kernel.-(started_at)
      |> System.convert_time_unit(:native, :millisecond)

    cond do
      age_ms < 1000 ->
        "just now"

      age_ms < 60_000 ->
        "#{div(age_ms, 1000)}s ago"

      true ->
        "#{div(age_ms, 60_000)}m ago"
    end
  end

  defp beam_lab_topic_data(topic) do
    Enum.find(beam_lab_topics(), &(&1.key == topic)) || hd(beam_lab_topics())
  end

  defp citizen_mailbox(citizen) do
    Map.get(citizen, :mailbox, [])
  end
end
