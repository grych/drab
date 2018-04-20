defmodule Drab.Waiter do
  require Logger

  @moduledoc """
  Enables Drab Waiter functionality - synchronous wait for browser events in the Commander handler
  function.

  This module is optional and is not loaded by default. You need to explicitly declare it in the
  commander:

      use Drab.Commander, modules: [Drab.Waiter]

  Introduces DSL for registering events. Syntax:

      waiter(socket) do
        on "selector1", "event_name", fn (sender) ->
        end
        on "selector2", "event_name", fn (sender) ->
        end
        on_timeout 5000, fn -> end
      end
  """

  use DrabModule
  @impl true
  def js_templates(), do: ["drab.waiter.js"]

  @doc """
  Main Waiter loop.

  Takes socket as an argument, returns the return value of the function which matched the selector
  and event.

  Inside the `do` block you may register Browser Events which Waiter will react to. See
  `Drab.Waiter.on`.
  """
  defmacro waiter(socket, do: block) do
    quote do
      {:ok, var!(buffer, Drab.Waiter)} = start_buffer(%{:timeout => {:infinity, nil}})

      unquote do
        block
      end

      {timeout, timeout_function} = get_buffer(var!(buffer, Drab.Waiter))[:timeout]
      waiters = buffer |> var!(Drab.Waiter) |> get_buffer() |> Map.delete(:timeout)
      :ok = stop_buffer(var!(buffer, Drab.Waiter))

      with_tokens =
        Enum.map(waiters, fn {ref, {selector, event_name, function, pid}} ->
          waiter_token = tokenize_waiter(unquote(socket), pid, ref)
          %{selector: selector, event_name: event_name, drab_waiter_token: waiter_token}
        end)

      Drab.push(unquote(socket), self(), nil, "register_waiters", waiters: with_tokens)

      ret =
        receive do
          {:waiter, ref, sender} ->
            {selector, event_name, function, pid} = waiters[ref]
            function.(sender)
        after
          timeout ->
            timeout_function.()
        end

      # TODO: remove token from with_tokens to save bandwitdh
      Drab.push(unquote(socket), self(), nil, "unregister_waiters", waiters: with_tokens)

      ret
    end
  end

  @doc """
  Registers Javascript `event_name` on `selector` in the Drab Waiter loop. When the main loop is
  launched, Drab freezes the current function process and starts waiting for the events. When event
  occurs, it matches it and runs the corresponding lambda.

  Example:

      ret = waiter(socket) do
        on "#button1", "click", fn(sender) -> sender["text"] end
        on "#input1", "keyup", fn(sender) -> sender["val"] end
      end

  Lambda receives sender: the same Map as the Event Handler does, known there are `dom_sender`.
  """
  defmacro on(selector, event_name, function) do
    quote bind_quoted: [selector: selector, event_name: event_name, function: function] do
      put_buffer(var!(buffer, Drab.Waiter), make_ref(), {selector, event_name, function, self()})
    end
  end

  @doc """
  Register timeout event in Drab Waiter loop. Launches anonymous function after given time (in
  milliseconds). When no timeout is given, Waiter will wait forever.

  Example:

      ret = waiter(socket) do
        on "#button1", "click", fn(sender) -> sender["text"] end
        on_timeout 5000, fn() -> "timed out" end
      end
  """
  defmacro on_timeout(timeout, function) do
    quote bind_quoted: [timeout: timeout, function: function] do
      put_buffer(var!(buffer, Drab.Waiter), :timeout, {timeout, function})
    end
  end

  @doc false
  def start_buffer(state), do: Agent.start_link(fn -> state end)

  @doc false
  def stop_buffer(buff), do: Agent.stop(buff)

  @doc false
  def put_buffer(buff, key, value),
    do: Agent.update(buff, fn state -> Map.put(state, key, value) end)

  @doc false
  def get_buffer(buff), do: Agent.get(buff, & &1)

  @doc false
  @spec tokenize_waiter(Phoenix.Socket.t(), pid, reference) :: String.t()
  def tokenize_waiter(socket, pid, ref) do
    Phoenix.Token.sign(socket, "drab_waiter_token", {pid, ref})
  end

  @doc false
  @spec detokenize_waiter(Phoenix.Socket.t(), String.t()) :: {pid, reference}
  def detokenize_waiter(socket, token) do
    {:ok, {pid, ref}} = Phoenix.Token.verify(socket, "drab_waiter_token", token, max_age: 86_400)
    {pid, ref}
  end
end
