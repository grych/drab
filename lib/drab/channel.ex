defmodule Drab.Channel do
  require Logger
  @moduledoc false

  use Phoenix.Channel

  def join("drab:" <> _, %{"path" => url_path, "drab_return" => controller_and_action_token}, socket) do
    {:ok, controller_and_action} = Phoenix.Token.verify(socket, "controller_and_action", controller_and_action_token)
    [controller, action] = String.split(controller_and_action, "#")

    socket_assigned = socket 
      |> assign(:controller, String.to_existing_atom(controller))
      |> assign(:action, String.to_existing_atom(action))
      |> assign(:url_path, url_path)

    {:ok, pid} = Drab.start_link(socket_assigned)
    {:ok, assign(socket_assigned, :drab_pid, pid)}
  end

  # def handle_in("query", %{"ok" => [query, sender_encrypted, reply]}, socket) do
  #   # sender contains PID of the process which sended the query
  #   {:ok, sender_decrypted} = Phoenix.Token.verify(socket, "sender", sender_encrypted)
  #   sender = sender_decrypted |> :erlang.binary_to_term

  #   # sender is waiting for the result
  #   send(sender, {:got_results_from_client, reply})
  #   {:noreply, assign(socket, query, reply)}
  # end

  def handle_in("execjs", %{"ok" => [sender_encrypted, reply]}, socket) do
    # sender contains PID of the process which sended the query
    # sender is waiting for the result
    send(sender(socket, sender_encrypted), 
      {
        :got_results_from_client, reply
      })

    {:noreply, socket}
  end

  def handle_in("modal", %{"ok" => [sender_encrypted, reply]}, socket) do
    # sends { :button, %{"Param" => "value"}}
    send(sender(socket, sender_encrypted), 
      {
        :got_results_from_client, 
        { 
          reply["button_clicked"] |> String.to_atom, 
          reply["params"]
        }
      })

    {:noreply, socket}
  end

  def handle_in("onload", _, socket) do
    # Client side provides the url path (location.path), which is a base to determine the name of the Drab Controller

    GenServer.cast(socket.assigns.drab_pid, {:onload, socket})
    {:noreply, socket}
  end

  def handle_in("event", %{"event" => event, "payload" => payload}, socket) do
    GenServer.cast(socket.assigns.drab_pid, {String.to_atom(event), socket, payload})
    {:noreply, socket}
  end   

  defp sender(socket, sender_encrypted) do
    {:ok, sender_decrypted} = Phoenix.Token.verify(socket, "sender", sender_encrypted)
    sender_decrypted |> :erlang.binary_to_term
  end
end
