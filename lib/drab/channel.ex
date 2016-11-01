defmodule Drab.Channel do
  use Phoenix.Channel
  require IEx
  require Logger

  def join("drab:" <> his_id, payload, socket) do
    {:ok, pid} = Drab.start_link(socket)
    {:ok, assign(socket, :drab_pid, pid)}
  end

  def handle_in("query", %{"ok" => [query, sender_encrypted, reply]}, socket) do
    sender = Cipher.decrypt(sender_encrypted) |> :erlang.binary_to_term
    send(sender, {:got_results_from_client, reply})
    {:noreply, assign(socket, query, reply)}
  end

  def handle_in("onload", %{"path" => url_path, "drab_return" => controller_and_action}, socket) do
    # Client side provides the url path (location.path), which is a base to determine the name of the Drab Controller
    # Logger.debug ":-:-: payload on load: #{inspect(payload)}"
    [controller, action] = String.split(Cipher.decrypt(controller_and_action), "#")
    socket_assigned = socket 
      |> assign(:controller, String.to_existing_atom(controller))
      |> assign(:action, String.to_existing_atom(action))
    GenServer.cast(socket.assigns.drab_pid, {:onload, socket_assigned})
    {:noreply, socket_assigned}
  end

  def handle_in("event", %{"event" => event, "payload" => payload}, socket) do
    GenServer.cast(socket.assigns.drab_pid, {String.to_atom(event), socket, payload})
    {:noreply, socket}
  end   
end
