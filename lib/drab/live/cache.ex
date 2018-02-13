defmodule Drab.Live.Cache do
  @moduledoc """
  This is the `Drab.Live` internal cache module. It doesn't expose any API.

  ### Cache File
  Drab.Live stores internal information in the file `priv/drab.live.cache`. To clean up the cache
  just delete it, but allways followed with the `mix clean` command, to ensure all Drab.Live templates will recompile.
  """
  @cache_file "drab.live.cache"

  require Logger
  # TODO: clean the table on mix clean

  # This module is the DETS cache for Drab Live expressions, amperes, partials, and shadow buffers.
  # DETS table is created and filled up during the compile-time.

  # Internal representation:
  # "expr_hash" => {:expr, expression, [:assigns], [:children]}
  # {"partial_hash", "ampere_id"} => [amperes]
  #   amperes - {:html | :prop | :attr, "tag", "prop_or_attr", expression, [:assigns], [:children]}
  #   one ampere_id may contain more amperes, for different properties or attributes
  # {"partial_hash", :assign} => ["ampere_ids"]
  # "partial_hash" => {"partial_path", [:assigns]}

  @doc false
  @spec start :: :ok
  def start() do
    # if :dets.info(cache_file()) == :undefined do
    {:ok, _} = :dets.open_file(cache_file(), type: :set, ram_file: true)
    # end
    :ok
  end

  @doc false
  @spec stop :: :ok
  def stop() do
    :dets.close(cache_file())
  end

  # Runtime function. Lookup in the already opened ETS cache
  @doc false
  @spec get(atom | String.t() | tuple) :: term
  def get(k) do
    val =
      case :dets.lookup(cache_file(), k) do
        [{_, v}] -> v
        [] -> nil
        _ -> raise "Can't find the expression or hash #{inspect(k)} in the Drab.Live.Cache"
      end

    val
  end

  @doc false
  @spec set(atom | String.t() | tuple, term) :: :ok
  def set(k, v) do
    :dets.insert(cache_file(), {k, v})
    :dets.sync(cache_file())
  end

  @doc false
  @spec add(atom | String.t() | tuple, term) :: :ok
  def add(k, v) do
    list = get(k) || []
    :dets.insert(cache_file(), {k, list ++ [v]})
    :dets.sync(cache_file())
  end

  @doc false
  @spec cache_file :: String.t()
  def cache_file() do
    # "#{Path.join(Drab.Config.app_name() |> :code.priv_dir() |> to_string(), @cache_file)}"
    "#{Path.join(:drab |> :code.priv_dir() |> to_string(), @cache_file)}"
  end
end
