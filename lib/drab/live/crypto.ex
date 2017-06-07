defmodule Drab.Live.Crypto do
  @moduledoc false
  alias Plug.Crypto.KeyGenerator
  alias Plug.Crypto.MessageEncryptor

  # :erlang.term_to_binary(make_ref()) |> :erlang.phash2() |> to_string() |> Base.url_encode64()
  # :erlang.term_to_binary(make_ref()) |> Base.url_encode64()
  def uuid(), do: {now_ms(), make_ref()} |> hash()

  # The most effective way for store assigns in the browser is basic encode
  def encode32(term) do
    term |> :erlang.term_to_binary() |> Base.encode32(padding: false, case: :lower)
    # :erlang.term_to_binary(term) |> :zlib.gzip() |> Base.url_encode64()
    # {now_ms(), term} |> :erlang.term_to_binary() |> :zlib.gzip() |> encrypt()
    # Drab.Core.encode_js(term)
    # Phoenix.Token.sign(Drab.Config.endpoint(), "Drab.Live.Crypto", term)
  end

  def decode32(string) do
    string |> Base.decode32!(padding: false, case: :lower) |> :erlang.binary_to_term()
    # string |> Base.url_decode64! |> :zlib.gunzip() |> :erlang.binary_to_term
    # {_millisecs, decoded} = string |> decrypt() |> :zlib.gunzip() |> :erlang.binary_to_term()
    # decoded
    # Drab.Core.decode_js(string)
    # {:ok, term} = Phoenix.Token.verify(Drab.Config.endpoint(), "Drab.Live.Crypto", string)
    # term
  end

  def encode64(term) do
    term |> :erlang.term_to_binary() |> Base.url_encode64()
  end

  def decode64(string) do
    string |> Base.url_decode64!() |> :erlang.binary_to_term()
  end

  def encrypt(term) do
    {secret, sign_secret} = keys()
    MessageEncryptor.encrypt(term, secret, sign_secret)
  end

  def decrypt(crypted) do
    {secret, sign_secret} = keys()
    {:ok, decrypted} = MessageEncryptor.decrypt(crypted, secret, sign_secret)
    decrypted
  end

  defp keys() do
    secret_key_base = Drab.Config.app_config(:secret_key_base)
    # secret_key_base = "dupa"
    secret = KeyGenerator.generate(secret_key_base, "Drab.Live.Crypto salt")
    sign_secret = KeyGenerator.generate(secret_key_base, "Drab.Live.Crypto sign salt")
    {secret, sign_secret}
  end

  defp now_ms(), do: System.system_time(:milli_seconds)

  def hash(term) do
    :erlang.phash2(term) |> to_string() |> Base.encode32(padding: false, case: :lower)
  end

end
