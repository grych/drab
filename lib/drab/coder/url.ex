defmodule Drab.Coder.URL do
  @moduledoc false

  @invalid_argument {:error, "invalid argument; only string is allowed"}

  @spec encode(String.t()) :: Drab.Coder.return()
  @doc """
  Urlencode given string.

      iex> Drab.Coder.URL.encode("test !/ Łódź&?")
      {:ok, "test+%21%2F+%C5%81%C3%B3d%C5%BA%26%3F"}
      iex> Drab.Coder.URL.encode(42)
      {:error, "invalid argument; only string is allowed"}
  """
  def encode(string) when is_binary(string), do: {:ok, URI.encode_www_form(string)}

  def encode(_), do: @invalid_argument

  @spec encode!(String.t()) :: String.t()
  @doc """
  Urlencode given string.

      iex> Drab.Coder.URL.encode!("test !/ Łódź&?")
      "test+%21%2F+%C5%81%C3%B3d%C5%BA%26%3F"
  """
  defdelegate encode!(string), to: URI, as: :encode_www_form

  @spec decode(String.t()) :: Drab.Coder.return()
  @doc """
  Urldecode the string.

      iex> Drab.Coder.URL.decode("test+%21%2F+%C5%81%C3%B3d%C5%BA%26%3F")
      {:ok, "test !/ Łódź&?"}
      iex> Drab.Coder.URL.decode(42)
      {:error, "invalid argument; only string is allowed"}
  """
  def decode(string) when is_binary(string), do: {:ok, URI.decode_www_form(string)}

  def decode(_), do: @invalid_argument

  @spec decode!(String.t()) :: String.t()
  @doc """
  Urldecode the string.

      iex> Drab.Coder.URL.decode!("test+%21%2F+%C5%81%C3%B3d%C5%BA%26%3F")
      "test !/ Łódź&?"
  """
  defdelegate decode!(string), to: URI, as: :decode_www_form
end
