defmodule Drab.Channel do
  require Logger
  @moduledoc false

  use Phoenix.Channel

  def join("drab:" <> url_path, _, socket) do
    # socket already contains controller and action
    socket_with_path = socket |> assign(:url_path, url_path)

    {:ok, pid} = Drab.start({%{}, self(), Drab.get_commander(socket)})
    socket_with_pid = assign(socket_with_path, :drab_pid, pid)

    # Drab.commander(socket).__drab_closing_waiter__(socket_with_pid)

    {:ok, socket_with_pid}
  end

  def handle_in("execjs", %{"ok" => [sender_encrypted, reply]}, socket) do
    # sender contains PID of the process which sent the query
    # sender is waiting for the result
    send(sender(socket, sender_encrypted), 
      {
        :got_results_from_client, reply
      })

    {:noreply, socket}
  end

  def handle_in("modal", %{"ok" => [sender_encrypted, reply]}, socket) do
    # sends { "button_name", %{"Param" => "value"}}
    send(sender(socket, sender_encrypted), 
      {
        :got_results_from_client, 
        { 
          reply["button_clicked"] |> String.to_existing_atom, 
          reply["params"]
        }
      })

    {:noreply, socket}
  end

  def handle_in("onload", %{"drab_store_token" => drab_store_token}, socket) do
    verify_and_cast(:onload, [], socket, drab_store_token)
  end

  def handle_in("onconnect", %{"drab_store_token" => drab_store_token}, socket) do
    verify_and_cast(:onconnect, [], socket, drab_store_token)
  end

  def handle_in("event", %{
      "event" => event_name, 
      "payload" => payload, 
      "event_handler_function" => event_handler_function,
      "reply_to" => reply_to,
      "drab_store_token" => drab_store_token}, socket) do
    # event_name is currently not used (0.2.0)
    verify_and_cast(event_name, [payload, event_handler_function, reply_to], socket, drab_store_token)
  end   

  defp verify_and_cast(message, params, socket, drab_store_token) do
    case Phoenix.Token.verify(socket, "drab_store_token", drab_store_token) do
      {:ok, drab_store} -> 
        socket_with_store = assign(socket, :drab_store, drab_store)
        p = [message, socket_with_store] ++ params
        GenServer.cast(socket.assigns.drab_pid, List.to_tuple(p))
        {:noreply, socket_with_store}
      {:error, reason} -> 
        raise "Can't verify the token: #{inspect(reason)}" # let it die
    end    
  end

  defp sender(socket, sender_encrypted) do
    {:ok, sender_decrypted} = Phoenix.Token.verify(socket, "sender", sender_encrypted)
    sender_decrypted |> :erlang.binary_to_term
  end
end
