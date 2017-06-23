defmodule Drab.Live.Cache do
  @moduledoc """
  This is the Drab.Live internal cache module. It doesn't expose any API.

  ### Cache File
  Drab.Live store internal information in the file `priv/hashes_expressions.drab.cache`. To clean up the cach,
  just delete it, but only with `mix clean` command, to ensure all Drab Live Templates will recompile.
  """
  @cache_file "priv/hashes_expressions.drab.cache"
  @name __MODULE__

  require Logger
  #TODO: clean the table on mix clean

  # This module is the DETS/ETS cache for Drab Live expressions, amperes, partials, and shadow buffers.
  # DETS table is created and filled up during the compile-time. In the runtime, it starts ETS during system startup.

  @doc false
  def start() do
    {:ok, dets} = :dets.open_file(@cache_file, [type: :set])
    cache = :ets.new(@name, [:set, :named_table])
    :dets.to_ets(dets, cache)
    :dets.close(dets)
    Logger.info "Started #{@name} ETS"
    :ok
  end

  # Runtime function. Lookup in the already opened ETS cache
  @doc false
  def get(k) do
    val = case :ets.lookup(@name, k) do
      [{_, v}] -> v
      [] -> nil
      _ -> raise "Can't find the expression or hash #{inspect k} in the Drab.Live.Cache"
    end
    val
  end

  # The following functions are supposed to be run only on the compile-time
  @doc false
  def set(k, v) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    :dets.insert(table, {k, v})
    # :ets.insert(@name, {k, v})
    :dets.close(table)
  end

  @doc false
  def add(k, v) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    list = get(k) || []
    :dets.insert(table, {k, list ++ [v]})
    # :ets.insert(@name, {k, list ++ [v]})
    :dets.close(table)
  end

  @doc false
  def dets_get(k) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    val = case :dets.lookup(table, k) do
      [{_, v}] -> v
      [] -> nil
      _ -> raise "Can't find the expression or hash #{inspect k} in the Drab.Live.Cache"
    end
    # [{_, v}] = :dets.lookup(table, k)
    :dets.close(table)
    val
  end
end


# defmodule DrabPoc.Presence do
#   @name {:global, __MODULE__}

#   require Logger

#   def start_link do
#     case Agent.start_link(fn -> %{} end, name: @name) do
#       {:ok, pid} ->
#         Logger.info "Started #{__MODULE__} server, PID: #{inspect pid}"
#         {:ok, pid}
#       {:error, {:already_started, pid}} ->
#         Logger.info "#{__MODULE__} is already running, server PID: #{inspect pid}"
#         # Process.monitor(pid)
#         {:ok, pid}
#     end
#   end

#   def add_user(node, pid, user), do: Agent.update(@name, &Map.put(&1, {node, pid}, user))

#   def get_user(node, pid), do: Agent.get(@name, &Map.get(&1, {node, pid}))

#   def update_user(node, pid, user), do: add_user(node, pid, user)

#   def remove_user(node, pid), do: Agent.update(@name, &Map.delete(&1, {node, pid}))

#   def get_users(), do: Agent.get(@name, fn map -> map end)
# end
