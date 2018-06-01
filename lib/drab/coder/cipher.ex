defmodule Drab.Coder.Cipher do
  @moduledoc false

  @spec encode(term) :: Drab.Coder.return()
  @doc """
  Encrypt any term and encode it to Base64.

      iex> {:ok, t} = Drab.Coder.Cipher.encode("test")
      iex> t != "test"
      true
  """
  def encode(term) do
    term
    |> Drab.Live.Crypto.encrypt()
    |> Drab.Coder.Base64.encode()
  end

  @spec encode!(term) :: String.t()
  @doc """
  Encrypt any term and encode it to Base64.

      iex> Drab.Coder.Cipher.encode!("test") != "test"
      true
  """
  def encode!(term) do
    term
    |> Drab.Live.Crypto.encrypt()
    |> Drab.Coder.Base64.encode!()
  end

  @spec decode(String.t()) :: Drab.Coder.return()
  @doc """
  Decrypt and base-64 decode string. Returns term.

      iex> {:ok, encoded} = Drab.Coder.Cipher.encode([1,2,3])
      iex> Drab.Coder.Cipher.decode(encoded)
      {:ok, [1,2,3]}
  """
  def decode(string) do
    case Drab.Coder.Base64.decode(string) do
      {:ok, encrypted} -> {:ok, Drab.Live.Crypto.decrypt(encrypted)}
      error -> error
    end
  end

  @spec decode!(String.t()) :: term
  @doc """
  Decrypt and base-64 decode string. Returns term.

      iex> encoded = Drab.Coder.Cipher.encode!(%{a: 1})
      iex> Drab.Coder.Cipher.decode!(encoded)
      %{a: 1}
  """
  def decode!(string) do
    string
    |> Drab.Coder.Base64.decode!()
    |> Drab.Live.Crypto.decrypt()
  end
end
