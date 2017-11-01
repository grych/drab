defmodule Drab.Live.Cache do
  @moduledoc """
  This is the Drab.Live internal cache module. It doesn't expose any API.

  ### Cache File
  Drab.Live stores internal information in the file `priv/drab.live.cache`. To clean up the cache
  just delete it, but only with the `mix clean` command, to ensure all Drab.Live templates will recompile.
  """
  @cache_file "drab.live.cache"

  require Logger
  #TODO: clean the table on mix clean

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
    # "#{Path.join(Drab.Config.app_name() |> :code.priv_dir() |> to_string(), @cache_file)}"
    "#{Path.join(:drab |> :code.priv_dir() |> to_string(), @cache_file)}"
  end
end
