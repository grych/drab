defmodule Drab.Ampere.Crypto do
  @moduledoc false

  def uuid(), do: :erlang.term_to_binary(make_ref()) |> Base.encode64

  #TODO: encrypt it
  def encode(term) do
    :erlang.term_to_binary(term) |> :zlib.gzip() |> Base.encode64
  end

  def decode(string) do
    string |> Base.decode64! |> :zlib.gunzip() |> :erlang.binary_to_term
  end

end
