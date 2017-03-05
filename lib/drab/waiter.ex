defmodule Drab.Waiter do
  require Logger

  defmacro waiter(socket, do: block) do
    quote do
      {:ok, var!(buffer, Drab.Waiter)} = start_buffer(%{:timeout => {:infinity, nil}})

      unquote do
        block
      end

      {timeout, timeout_function} = get_buffer(var!(buffer, Drab.Waiter))[:timeout]
      waiters = get_buffer(var!(buffer, Drab.Waiter)) |> Map.delete(:timeout)
      :ok = stop_buffer(var!(buffer, Drab.Waiter))

      Enum.map waiters, fn {ref, {selector, event_name, function, pid}} -> 
        waiter_token = tokenize_waiter(unquote(socket), pid, ref)
        Drab.push(unquote(socket), self(), "register_waiter", 
          selector: selector, 
          event_name: event_name,
          drab_waiter_token: waiter_token)
      end

      receive do
        {:waiter, ref, sender} ->
          {selector, event_name, function, pid} = waiters[ref]
          function.(sender)
        after timeout ->
          timeout_function.()
      end
    end
  end

  defmacro on(selector, event_name, function) do
    quote bind_quoted: [selector: selector, event_name: event_name, function: function] do
      put_buffer(var!(buffer, Drab.Waiter), make_ref(), {selector, event_name, function, self()})
    end
  end

  defmacro on_timeout(timeout, function) do
    quote bind_quoted: [timeout: timeout, function: function] do
      put_buffer(var!(buffer, Drab.Waiter), :timeout, {timeout, function})
    end
  end

  def start_buffer(state), do: Agent.start_link(fn -> state end)

  def stop_buffer(buff), do: Agent.stop(buff)

  def put_buffer(buff, key, value), do: Agent.update(buff, fn state -> Map.put(state, key, value) end)

  def get_buffer(buff), do: Agent.get(buff, &(&1)) 

  def tokenize_waiter(socket, pid, ref) do
    Phoenix.Token.sign(socket, "drab_waiter_token",  {pid, ref})
  end

  def detokenize_waiter(socket, token) do
    {:ok, {pid, ref}} = Phoenix.Token.verify(socket, "drab_waiter_token", token)
    {pid, ref}
  end
end
