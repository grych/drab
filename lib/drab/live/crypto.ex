defmodule Drab.Live.Crypto do
  @moduledoc false

  # :erlang.term_to_binary(make_ref()) |> :erlang.phash2() |> to_string() |> Base.encode64()
  # :erlang.term_to_binary(make_ref()) |> Base.encode64()
  def uuid(), do: make_ref() |> hash()

  #TODO: encrypt it
  def encode(term) do
    :erlang.term_to_binary(term) |> :zlib.gzip() |> Base.encode64()
  end

  def decode(string) do
    string |> Base.decode64! |> :zlib.gunzip() |> :erlang.binary_to_term
  end

  def hash(term) do
    :erlang.phash2(term) |> to_string() |> Base.encode64()
  end
end
