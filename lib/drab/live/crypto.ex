defmodule Drab.Live.Crypto do
  @moduledoc false

  alias Plug.Crypto.KeyGenerator
  alias Plug.Crypto.MessageEncryptor

  @doc false
  @spec uuid :: String.t()
  @spec uuid(String.t()) :: String.t()
  def uuid(begin_with \\ "u"), do: begin_with <> hash({now_ms(), make_ref()})

  # The most effective way for store assigns in the browser is basic encode
  @doc false
  @spec encode32(term) :: String.t()
  def encode32(term) do
    term |> :erlang.term_to_binary() |> Base.encode32(padding: false, case: :lower)
  end

  @doc false
  @spec decode32(String.t()) :: term()
  def decode32(string) do
    string |> Base.decode32!(padding: false, case: :lower) |> :erlang.binary_to_term()
  end

  @doc false
  @spec encode64(term) :: String.t()
  def encode64(term) do
    # term |> :erlang.term_to_binary() |> Base.url_encode64()
    encrypt(term)
  end

  @doc false
  @spec decode64(String.t()) :: term()
  def decode64(string) do
    # string |> Base.url_decode64!() |> :erlang.binary_to_term()
    decrypt(string)
  end

  @doc false
  @spec encrypt(term) :: String.t()
  def encrypt(term) do
    {secret, sign_secret} = keys()
    MessageEncryptor.encrypt(:erlang.term_to_binary(term), secret, sign_secret)
  end

  @doc false
  @spec decrypt(String.t()) :: term
  def decrypt(crypted) do
    {secret, sign_secret} = keys()
    {:ok, decrypted} = MessageEncryptor.decrypt(crypted, secret, sign_secret)
    :erlang.binary_to_term(decrypted)
  end

  @doc false
  @spec keys :: {String.t(), String.t()}
  defp keys() do
    secret_key_base = Drab.Config.app_config(:secret_key_base)
    secret = KeyGenerator.generate(secret_key_base, "Drab.Live.Crypto salt")
    sign_secret = KeyGenerator.generate(secret_key_base, "Drab.Live.Crypto sign salt")
    {secret, sign_secret}
  end

  @spec now_ms :: integer
  defp now_ms(), do: System.system_time(:millisecond)

  @doc false
  @spec hash(term) :: String.t()
  def hash(term) do
    term
    |> :erlang.phash2(4_294_967_296)
    |> to_string()
    |> Base.encode32(padding: false, case: :lower)
  end
end
