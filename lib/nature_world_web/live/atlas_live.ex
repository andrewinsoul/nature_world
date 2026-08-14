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
       education_event: nil
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

    {:noreply,
     assign(socket,
       selected_citizen_id: selected_citizen_id,
       message_recipient_id: message_recipient_id,
       message_form: message_form(message_recipient_id)
     )}
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

    socket =
      if selected_id && recipient_id && recipient_id != selected_id do
        NatureWorld.Citizen.greet(recipient_id, selected_id)

        show_education(socket, %{
          kind: :message,
          sender: selected_id,
          recipient: recipient_id
        })
      else
        socket
      end

    {:noreply,
     assign(socket,
       message_recipient_id: recipient_id,
       message_form: message_form(recipient_id),
       beam_lab_topic: :message_passing
     )}
  end

  @impl true
  def handle_event("crash-selected", _params, socket) do
    case socket.assigns.selected_citizen_id do
      nil ->
        {:noreply, socket}

      id ->
        NatureWorld.Citizen.crash(id)

        {:noreply,
         socket
         |> assign(beam_lab_topic: :supervision)
         |> show_education(%{kind: :crash, citizen: id})}
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

        {:noreply,
         socket
         |> assign(beam_lab_topic: :fault_tolerance)
         |> show_education(%{kind: :crash, citizen: id})}
    end
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

  defp show_education(socket, event) do
    ref = make_ref()
    Process.send_after(self(), {:clear_education, ref}, 4500)
    assign(socket, education_event: Map.put(event, :ref, ref))
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
end
