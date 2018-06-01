defmodule Drab.Coder.String do
  @moduledoc false

  @spec encode(term) :: Drab.Coder.return()
  @doc """
  Encrypt any term and encode it to Base64.

      iex> {:ok, t} = Drab.Coder.String.encode(1)
      iex> t
      "g2EB"
  """
  def encode(term) do
    term
    |> :erlang.term_to_binary()
    |> Drab.Coder.Base64.encode()
  end

  @spec encode!(term) :: String.t()
  @doc """
  Encrypt any term and encode it to Base64.

      iex> Drab.Coder.String.encode!("test")
      "g20AAAAEdGVzdA=="
  """
  def encode!(term) do
    term
    |> :erlang.term_to_binary()
    |> Drab.Coder.Base64.encode!()
  end

  @spec decode(String.t()) :: Drab.Coder.return()
  @doc """
  Decrypt and base-64 decode string. Returns term.

      iex> {:ok, encoded} = Drab.Coder.String.encode([1,2,3])
      iex> Drab.Coder.String.decode(encoded)
      {:ok, [1,2,3]}
  """
  def decode(string) do
    case Drab.Coder.Base64.decode(string) do
      {:ok, s} -> {:ok, :erlang.binary_to_term(s)}
      error -> error
    end
  end

  @spec decode!(String.t()) :: term
  @doc """
  Decrypt and base-64 decode string. Returns term.

      iex> encoded = Drab.Coder.String.encode!(%{a: 1})
      iex> Drab.Coder.String.decode!(encoded)
      %{a: 1}
  """
  def decode!(string) do
    string
    |> Drab.Coder.Base64.decode!()
    |> :erlang.binary_to_term()
  end
end
