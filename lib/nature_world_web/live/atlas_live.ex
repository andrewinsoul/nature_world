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

    world = NatureWorld.Simulation.state()
    message_recipient_id = default_recipient_id(world.citizens, nil, nil)

    {:ok,
     assign(socket,
       world: world,
       selected_citizen_id: nil,
       message_recipient_id: message_recipient_id,
       message_form: message_form(message_recipient_id),
       beam_lab_topic: :message_passing,
       education_event: nil,
       tutorial: tutorial(:welcome)
     )}
  end

  @impl true
  def handle_event("select-citizen", %{"id" => id}, socket) do
    selected_citizen_id = String.to_integer(id)

    message_recipient_id =
      default_recipient_id(
        socket.assigns.world.citizens,
        selected_citizen_id,
        socket.assigns.message_recipient_id
      )

    socket =
      assign(socket,
        selected_citizen_id: selected_citizen_id,
        message_recipient_id: message_recipient_id,
        message_form: message_form(message_recipient_id)
      )
      |> maybe_advance_tutorial(:welcome)

    {:noreply, socket}
  end

  @impl true
  def handle_event("set-recipient", %{"message" => %{"recipient_id" => recipient_id}}, socket) do
    recipient_id =
      parse_id(recipient_id)

    {:noreply,
     assign(socket,
       message_recipient_id: recipient_id,
       message_form: message_form(recipient_id)
     )}
  end

  @impl true
  def handle_event("send-message", %{"message" => %{"recipient_id" => recipient_id}}, socket) do
    selected_id = socket.assigns.selected_citizen_id
    recipient_id = parse_id(recipient_id)
    message_sent? =
      selected_id != nil and recipient_id != nil and recipient_id != selected_id

    socket =
      if message_sent? do
        NatureWorld.Citizen.greet(recipient_id, selected_id)

        show_education(socket, %{
          kind: :message,
          sender: selected_id,
          recipient: recipient_id
        })
      else
        socket
      end

    socket =
      assign(socket,
        message_recipient_id: recipient_id,
        message_form: message_form(recipient_id),
        beam_lab_topic: :message_passing
      )

    socket =
      if message_sent? do
        maybe_advance_tutorial(socket, :message_passing)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("crash-selected", _params, socket) do
    case socket.assigns.selected_citizen_id do
      nil ->
        {:noreply, socket}

      id ->
        NatureWorld.Citizen.crash(id)

        socket =
          socket
          |> assign(beam_lab_topic: :supervision)
          |> show_education(%{kind: :crash, citizen: id})
          |> maybe_complete_tutorial()

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("crash-random", _params, socket) do
    case socket.assigns.world.citizens do
      [] ->
        {:noreply, socket}

      citizens ->
        id = citizens |> Enum.random() |> Map.fetch!(:id)
        NatureWorld.Citizen.crash(id)

        socket =
          socket
          |> assign(beam_lab_topic: :fault_tolerance)
          |> show_education(%{kind: :crash, citizen: id})
          |> maybe_complete_tutorial()

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("tutorial-next", _params, socket) do
    {:noreply, advance_tutorial(socket)}
  end

  @impl true
  def handle_event("dismiss-tutorial", _params, socket) do
    {:noreply, assign(socket, tutorial: nil)}
  end

  @impl true
  def handle_event("select-lab-topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, beam_lab_topic: lab_topic(topic))}
  end

  @impl true
  def handle_info({:tick, state}, socket) do
    message_recipient_id =
      default_recipient_id(
        state.citizens,
        socket.assigns.selected_citizen_id,
        socket.assigns.message_recipient_id
      )

    {:noreply,
     assign(socket,
       world: state,
       message_recipient_id: message_recipient_id,
       message_form: message_form(message_recipient_id)
     )}
  end

  @impl true
  def handle_info({:clear_education, ref}, %{assigns: %{education_event: %{ref: ref}}} = socket) do
    {:noreply, assign(socket, education_event: nil)}
  end

  def handle_info({:clear_education, _ref}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:clear_tutorial, ref}, %{assigns: %{tutorial: %{ref: ref}}} = socket) do
    {:noreply, assign(socket, tutorial: nil)}
  end

  def handle_info({:clear_tutorial, _ref}, socket), do: {:noreply, socket}

  defp show_education(socket, event) do
    ref = make_ref()
    Process.send_after(self(), {:clear_education, ref}, 4500)
    assign(socket, education_event: Map.put(event, :ref, ref))
  end

  defp maybe_advance_tutorial(socket, step) do
    case socket.assigns.tutorial do
      %{step: ^step} ->
        advance_tutorial(socket)

      _ ->
        socket
    end
  end

  defp maybe_complete_tutorial(socket) do
    case socket.assigns.tutorial do
      %{step: :message_passing} ->
        assign(socket, tutorial: tutorial(:supervision))

      %{step: :supervision} ->
        complete_tutorial(socket)

      _ ->
        socket
    end
  end

  defp advance_tutorial(socket) do
    case socket.assigns.tutorial do
      %{step: :welcome} ->
        assign(socket, tutorial: tutorial(:message_passing))

      %{step: :message_passing} ->
        assign(socket, tutorial: tutorial(:supervision))

      %{step: :supervision} ->
        complete_tutorial(socket)

      %{step: :complete} ->
        assign(socket, tutorial: nil)

      _ ->
        socket
    end
  end

  defp complete_tutorial(socket) do
    ref = make_ref()
    Process.send_after(self(), {:clear_tutorial, ref}, 5000)

    assign(socket, tutorial: Map.put(tutorial(:complete), :ref, ref))
  end

  def recipient_options(citizens, selected_citizen_id) do
    citizens
    |> Enum.reject(&(&1.id == selected_citizen_id))
    |> Enum.map(fn citizen ->
      {"Citizen #{citizen.id}", citizen.id}
    end)
  end

  defp default_recipient_id(citizens, selected_id, current_recipient_id) do
    valid_current_recipient? =
      current_recipient_id &&
        Enum.any?(citizens, fn citizen ->
          citizen.id == current_recipient_id and citizen.id != selected_id
        end)

    cond do
      valid_current_recipient? ->
        current_recipient_id

      true ->
        citizens
        |> Enum.find_value(fn citizen ->
          if citizen.id != selected_id, do: citizen.id, else: nil
        end)
    end
  end

  defp message_form(recipient_id) do
    value =
      case recipient_id do
        nil -> ""
        id -> Integer.to_string(id)
      end

    to_form(%{"recipient_id" => value}, as: :message)
  end

  defp parse_id(""), do: nil
  defp parse_id(nil), do: nil

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp lab_topic("message_passing"), do: :message_passing
  defp lab_topic("process_isolation"), do: :process_isolation
  defp lab_topic("supervision"), do: :supervision
  defp lab_topic("fault_tolerance"), do: :fault_tolerance
  defp lab_topic(_), do: :message_passing

  defp tutorial(:welcome) do
    %{
      step: :welcome,
      step_index: 1,
      total_steps: 3,
      title: "Welcome to Nature World",
      body:
        "Start by clicking any citizen. Each citizen is a real Elixir process with its own state.",
      guidance: "Click a citizen to inspect its process state.",
      action_label: "Next tip",
      action_event: "tutorial-next",
      secondary_label: "Skip tutorial",
      secondary_event: "dismiss-tutorial"
    }
  end

  defp tutorial(:message_passing) do
    %{
      step: :message_passing,
      step_index: 2,
      total_steps: 3,
      title: "Message Passing",
      body:
        "Send a message from the selected citizen to watch asynchronous communication in action.",
      guidance: "Pick a recipient and send a message.",
      action_label: "Next tip",
      action_event: "tutorial-next",
      secondary_label: "Skip tutorial",
      secondary_event: "dismiss-tutorial"
    }
  end

  defp tutorial(:supervision) do
    %{
      step: :supervision,
      step_index: 3,
      total_steps: 3,
      title: "Supervision",
      body:
        "Crash a citizen to see the supervisor restart it while the rest of the world keeps running.",
      guidance: "Try crashing the selected citizen or a random one.",
      action_label: "Show me the finish",
      action_event: "tutorial-next",
      secondary_label: "Skip tutorial",
      secondary_event: "dismiss-tutorial"
    }
  end

  defp tutorial(:complete) do
    %{
      step: :complete,
      step_index: 3,
      total_steps: 3,
      title: "You're ready to explore",
      body:
        "You've seen selection, message passing, and supervision. Keep experimenting with the world.",
      guidance: "The tutorial will close automatically in a moment.",
      action_label: "Continue exploring",
      action_event: "dismiss-tutorial",
      secondary_label: nil,
      secondary_event: nil
    }
  end
end
