defmodule Drab.Live.Cache do
  @moduledoc """
  This is the Drab.Live internal cache module. It doesn't expose any API.

  ### Cache File
  Drab.Live store internal information in the file `priv/hashes_expressions.drab.cache`. To clean up the cach,
  just delete it, but only with `mix clean` command, to ensure all Drab Live Templates will recompile.
  """
  @cache_file "hashes_expressions.drab.cache"
  # @name __MODULE__

  require Logger
  #TODO: clean the table on mix clean

  @env Mix.env()
  defp env(), do: @env

  # This module is the DETS cache for Drab Live expressions, amperes, partials, and shadow buffers.
  # DETS table is created and filled up during the compile-time.

  @doc false
  def start() do
    # if :dets.info(cache_file()) == :undefined do
      {:ok, _} = :dets.open_file(cache_file(), [type: :set, ram_file: true])
    # end
    :ok
  end

  @doc false
  def stop() do
    :dets.close(cache_file())
  end

  # Runtime function. Lookup in the already opened ETS cache
  @doc false
  def get(k) do
    val = case :dets.lookup(cache_file(), k) do
      [{_, v}] -> v
      [] -> nil
      _ -> raise "Can't find the expression or hash #{inspect k} in the Drab.Live.Cache"
    end
    val
  end

  @doc false
  def set(k, v) do
    :dets.insert(cache_file(), {k, v})
    :dets.sync(cache_file())
  end

  @doc false
  def add(k, v) do
    list = get(k) || []
    :dets.insert(cache_file(), {k, list ++ [v]})
    :dets.sync(cache_file())
  end

  @doc false
  def cache_file() do
    "#{Path.join(Drab.Config.app_name() |> :code.priv_dir() |> to_string(), @cache_file)}.#{env()}"
  end
end


