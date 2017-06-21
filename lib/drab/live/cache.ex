defmodule Drab.Live.Cache do
  @cache_file "priv/hashes_expressions.drab.cache"
  #TODO: clean the table
  #TODO: run the cache process on application load

  # it is calling only in a compile time, so this is OK so far
  def set(k, v) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    :dets.insert(table, {k, v})
    :dets.close(table)
  end

  def add(k, v) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    list = get(k) || []
    :dets.insert(table, {k, list ++ [v]})
    :dets.close(table)
  end

  def get(k) do
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
