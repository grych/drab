defmodule Drab.Live.Cache do
  @moduledoc """
  This is the `Drab.Live` internal cache module. It doesn't expose any API.

  ### Cache File
  Drab.Live stores internal information in the file `priv/drab.live.cache`. To clean up the cache
  just delete it, but allways followed with the `mix clean` command, to ensure all Drab.Live templates will recompile.
  """
  @cache_file "drab.live.cache"

  require Logger

  # This module is the DETS cache for Drab Live expressions, amperes, partials, and shadow buffers.
  # DETS table is created and filled up during the compile-time.

  # Internal representation:
  # "expr_hash" => {:expr, expression, [:assigns], [:parent_assigns]}
  # {"partial_hash", "ampere_id"} => [amperes]
  #   amperes - {:html | :prop | :attr, "tag", "prop_or_attr", expression, [:assigns], [:children]}
  #   one ampere_id may contain more amperes, for different properties or attributes
  # {"partial_hash", :assign} => ["ampere_ids"]
  # "partial_hash" => {"partial_path", [:assigns]}

  @spec partial_hash(atom, String.t()) :: String.t() | no_return
  def partial_hash(view, partial_name) do
    path = partial_path(view, partial_name)
    Drab.Live.Crypto.hash(path)
  end

  # no spec, sorry
  def template_name(partial_name, partial_hash) do
    module = partial_cache_module(partial_hash)
    unless Code.ensure_loaded?(module), do: Drab.Live.raise_partial_not_found(partial_name)
    module.path() |> Path.basename() |> Path.rootname(Drab.Config.drab_extension())
  end

  @spec partial_path(atom, String.t()) :: String.t()
  defp partial_path(view, partial_name) do
    templates_path(view) <> partial_name <> Drab.Config.drab_extension()
  end

  @spec partial_cache_module(String.t()) :: atom
  defp partial_cache_module(hash), do: Drab.Live.Engine.module_name(hash)

  @spec templates_path(atom) :: String.t()
  defp templates_path(view) do
    {path, _, _} = view.__templates__()
    path <> "/"
  end




  ### OLD:

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
