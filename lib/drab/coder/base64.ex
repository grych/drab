defmodule Drab.Coder.Base64 do
  @moduledoc false

  @invalid_argument {:error, "invalid argument; only string is allowed"}

  @spec encode(term) :: Drab.Coder.return()
  @doc """
  Encode string to Base64.

      iex> Drab.Coder.Base64.encode("test")
      {:ok, "dGVzdA=="}
      iex> Drab.Coder.Base64.encode(42)
      {:error, "invalid argument; only string is allowed"}
  """
  def encode(string) when is_binary(string), do: {:ok, Base.encode64(string)}
  def encode(_), do: @invalid_argument

  @spec encode!(String.t()) :: String.t()
  @doc """
  Bang version of encode/1.

      iex> Drab.Coder.Base64.encode!("test")
      "dGVzdA=="
  """
  defdelegate encode!(string), to: Base, as: :encode64

  @doc """
  Decode string from Base64.

      iex> Drab.Coder.Base64.decode("dGVzdA==")
      {:ok, "test"}
      iex> Drab.Coder.Base64.decode(42)
      {:error, "invalid argument; only string is allowed"}
  """
  @spec decode(String.t()) :: Drab.Coder.return()
  def decode(string) when is_binary(string) do
    case Base.decode64(string) do
      :error -> {:error, "string is not base-64 encoded"}
      result -> result
    end
  end
  def decode(_), do: @invalid_argument

  @doc """
  Bang version of decode/1

      iex> Drab.Coder.Base64.decode!("dGVzdA==")
      "test"
  """
  @spec decode!(String.t()) :: String.t()
  defdelegate decode!(string), to: Base, as: :decode64!
end
