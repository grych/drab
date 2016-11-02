defmodule Drab.Channel do
  @moduledoc false

  use Phoenix.Channel

  def join("drab:" <> _his_id, _payload, socket) do
    {:ok, pid} = Drab.start_link(socket)
    {:ok, assign(socket, :drab_pid, pid)}
  end

  def handle_in("query", %{"ok" => [query, sender_encrypted, reply]}, socket) do
    # sender contains PID of the process which sended the query
    {:ok, sender_decrypted} = Phoenix.Token.verify(socket, "sender", sender_encrypted)
    sender = sender_decrypted |> :erlang.binary_to_term

    # sender is waiting for the result
    send(sender, {:got_results_from_client, reply})
    {:noreply, assign(socket, query, reply)}
  end

  def handle_in("onload", %{"path" => _url_path, "drab_return" => controller_and_action_token}, socket) do
    # Client side provides the url path (location.path), which is a base to determine the name of the Drab Controller
    {:ok, controller_and_action} = Phoenix.Token.verify(socket, "controller_and_action", controller_and_action_token)
    [controller, action] = String.split(controller_and_action, "#")

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
