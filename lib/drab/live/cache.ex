defmodule Drab.Live.Cache do
  @cache_file "priv/hashes_expressions.drab.cache"
  #TODO: clean the table
  #TODO: run the cache process on application load

  # it is calling only in a compile time, so this is OK
  def add(k, v) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    :dets.insert(table, {k, v})
    :dets.close(table)
  end

  def get(k) do
    {:ok, table} = :dets.open_file(@cache_file, [type: :set])
    [{_, v}] = :dets.lookup(table, k)
    :dets.close(table)
    v
  end
end
