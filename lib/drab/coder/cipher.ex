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
    {:ok, Drab.Live.Crypto.encrypt(term)}
  end

  @spec encode!(term) :: String.t()
  @doc """
  Encrypt any term and encode it to Base64.

      iex> Drab.Coder.Cipher.encode!("test") != "test"
      true
  """
  def encode!(term) do
    Drab.Live.Crypto.encrypt(term)
  end

  @spec decode(String.t()) :: Drab.Coder.return()
  @doc """
  Decrypt and base-64 decode string. Returns term.

      iex> {:ok, encoded} = Drab.Coder.Cipher.encode([1,2,3])
      iex> Drab.Coder.Cipher.decode(encoded)
      {:ok, [1,2,3]}
  """
  def decode(string) do
    case Drab.Live.Crypto.decrypt(string) do
      :error -> {:error, "can't decrypt"}
      decrypted -> {:ok, decrypted}
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
    case Drab.Live.Crypto.decrypt(string) do
      :error -> raise "can't decrypt"
      decrypted -> decrypted
    end
  end
end
