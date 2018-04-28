defmodule Drab.Live.Assign do
  @moduledoc false

  @spec trim(term) :: term
  @doc """
  Reduces size of the assigns by shrinking @conn to include only the essential information
  (by default it is .private.phoenix_endpoint only).
  """
  def trim(%Plug.Conn{} = conn) do
    filter = Drab.Config.get(:live_conn_pass_through)
    trim(conn, filter)
  end

  def trim(other), do: other

  def trim(struct, filter) do
    filtered = filter(struct, filter)
    merge(struct(struct.__struct__), filtered)
  end

  def filter(%Plug.Conn{} = conn) do
    filter = Drab.Config.get(:live_conn_pass_through)
    filter(conn, filter)
  end

  def filter(other), do: other

  def filter(struct, filter) do
    deep_filter_map(struct, filter)
  end

  def merge(%Plug.Conn{} = conn, map) do
    merged = deep_merge_map(conn, map)
    struct(%Plug.Conn{}, merged)
  end

  def merge(other), do: other

  # all hails to @OvermindDL1 for this idea and the following functions
  defp deep_filter_map(%{__struct__: _} = struct, map_filter) do
    deep_filter_map(Map.from_struct(struct), map_filter)
  end

  defp deep_filter_map(original, map_filter) do
    original
    |> Enum.flat_map(fn {key, value} = set ->
      case map_filter[key] do
        true ->
          [set]

        %{} = map_filter when is_map(value) ->
          value = deep_filter_map(value, map_filter)
          if map_size(value) === 0, do: [], else: [{key, value}]

        _ ->
          []
      end
    end)
    |> Enum.into(%{})
  end

  defp deep_merge_map(%{__struct__: _} = struct, to_merge) do
    deep_merge_map(Map.from_struct(struct), to_merge)
  end

  defp deep_merge_map(base, to_merge) do
    to_merge
    |> Enum.reduce(base, fn
      {key, %{} = value}, base ->
        sub = base[key] || %{}
        sub = if is_map(sub), do: deep_merge_map(sub, value), else: sub
        Map.put(base, key, sub)

      {key, value}, base ->
        Map.put(base, key, value)
    end)
  end
end
