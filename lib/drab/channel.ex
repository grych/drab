defmodule Drab.Channel do
  @moduledoc false

  use Phoenix.Channel, Drab.Config.get(:phoenix_channel_options)

  @spec join(String.t(), any, Phoenix.Socket.t()) :: {:ok, Phoenix.Socket.t()}
  def join("__drab:" <> _broadcast_topic, _, socket) do
    # socket already contains controller and action
    {:ok, pid} = Drab.start_link(socket)
    socket_with_pid = assign(socket, :__drab_pid, pid)

    {:ok, socket_with_pid}
    # {:ok, assign(socket_with_pid, :topics, [])}
  end

  @spec handle_in(String.t(), map, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_in("execjs", %{"ok" => [sender_encrypted, reply]}, socket) do
    # sender contains PID of the process which sent the query
    # sender is waiting for the result
    {sender, ref} = sender(socket, sender_encrypted)
    send(sender, {:got_results_from_client, :ok, ref, reply})

    {:noreply, socket}
  end

  def handle_in("execjs", %{"error" => [sender_encrypted, reply]}, socket) do
    {sender, ref} = sender(socket, sender_encrypted)
    send(sender, {:got_results_from_client, :error, ref, reply})

    {:noreply, socket}
  end

  def handle_in("modal", %{"ok" => [sender_encrypted, reply]}, socket) do
    {sender, ref} = sender(socket, sender_encrypted)

    send(sender, {
      :got_results_from_client,
      :ok,
      ref,
      {
        String.to_existing_atom(reply["button_clicked"]),
        Map.delete(reply["params"], "__drab_modal_hidden_input")
      }
    })

    {:noreply, socket}
  end

  def handle_in("waiter", %{"drab_waiter_token" => waiter_token, "sender" => sender}, socket) do
    {pid, ref} = Drab.Waiter.detokenize_waiter(socket, waiter_token)

    send(pid, {:waiter, ref, sender})

    {:noreply, socket}
  end

  def handle_in("onload", payload, socket) do
    verify_and_cast(:onload, [payload], socket)
  end

  def handle_in("onconnect", payload, socket) do
    # for debugging
    if IEx.started?() do
      commander = Drab.get_commander(socket)
      modules = DrabModule.all_modules_for(commander.__drab__().modules)

      grouped =
        modules
        |> Enum.map(fn module ->
          [_ | rest] = Module.split(module)
          Enum.join(rest, ".")
        end)
        |> Enum.join(", ")

      live_example = %{Drab.Live => "socket |> poke(text: \"This assign has been drabbed!\")"}

      other_examples = %{
        Drab.Element => "socket |> set_style(\"body\", backgroundColor: \"red\")",
        Drab.Query => "socket |> select(:htmls, from: \"h4\")",
        Drab.Modal =>
          "socket |> alert(\"Title\", \"Sure?\", buttons: [ok: \"Azaliż\", cancel: \"Poniechaj\"])",
        Drab.Core => "socket |> exec_js(\"alert('hello from IEx!')\")"
      }

      module_examples = Map.merge(live_example, other_examples)

      examples =
        modules
        |> Enum.map(fn module -> module_examples[module] end)
        |> Enum.filter(fn x -> !is_nil(x) end)

      p = inspect(socket.assigns.__drab_pid)
      pid_string = ~r/#PID<(?<pid>.*)>/ |> Regex.named_captures(p) |> Map.get("pid")

      IO.puts("""

          Started Drab for #{socket.topic}, handling events in #{inspect(commander)}
          You may debug Drab functions in IEx by copy/paste the following:
      import Drab.{#{grouped}}
      socket = Drab.get_socket(pid("#{pid_string}"))

          Examples:
      #{Enum.join(examples, "\n")}
      """)
    end

    session = Drab.Core.detokenize_store(socket, payload["drab_session_token"])
    socket = assign(socket, :__session, session)
    store = Drab.Core.detokenize_store(socket, payload["drab_store_token"])
    socket = assign(socket, :__store, store)

    Drab.set_socket(socket.assigns.__drab_pid, socket)
    verify_and_cast(:onconnect, [payload], socket)
  end

  def handle_in(
        "event",
        %{
          # "event" => event_name,
          "payload" => payload,
          "event_handler_function" => event_handler_function,
          "reply_to" => reply_to
        },
        socket
      ) do
    verify_and_cast(:event, [payload, event_handler_function, reply_to], socket)
  end

  def handle_info({:subscribe, %{topic: topic, endpoint: endpoint}}, state) do
    :ok = endpoint.subscribe(topic)
    {:noreply, state}
  end

  def handle_info({:unsubscribe, %{topic: topic, endpoint: endpoint}}, state) do
    :ok = endpoint.unsubscribe(topic)
    {:noreply, state}
  end

  def handle_info(%Phoenix.Socket.Broadcast{topic: _, event: ev, payload: payload}, socket) do
    push(socket, ev, payload)
    {:noreply, socket}
  end

  @spec verify_and_cast(atom, list, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  defp verify_and_cast(event_name, params, socket) do
    p = [event_name, socket] ++ params
    GenServer.cast(socket.assigns.__drab_pid, List.to_tuple(p))
    {:noreply, socket}
  end

  @spec sender(Phoenix.Socket.t(), String.t()) :: {pid, reference}
  defp sender(socket, sender_encrypted) do
    Drab.detokenize(socket, sender_encrypted)
  end
end
