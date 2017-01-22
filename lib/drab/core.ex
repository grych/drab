defmodule Drab.Core do
  @moduledoc """
  """
  require Logger

  @doc """
  Synchronously executes the given javascript on the client side and returns value.
  """
  def execjs(socket, js) do
    # Phoenix.Channel.push(socket, "execjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.push(socket, self(), "execjs", js: js)

    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  @doc """
  Asynchronously broadcasts given javascript to all browsers displaying current page.
  """
  def broadcastjs(socket, js) do
    # Phoenix.Channel.broadcast(socket, "broadcastjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.broadcast(socket, self(), "broadcastjs", js: js)
    socket
  end

  @doc """
  Sends the log to the browser console for debugging
  """
  def console(socket, log) do
    do_console(socket, log, &Drab.push/4)
  end

  @doc """
  Broadcasts the log to the browsers console for debugging
  """
  def console!(socket, log) do
    do_console(socket, log, &Drab.broadcast/4)
  end

  defp do_console(socket, log, push_or_broadcast_function) do
    push_or_broadcast_function.(socket, self(), "console",  log: log)
  end

  @doc false
  def encode_js(value), do: Poison.encode!(value)

end
