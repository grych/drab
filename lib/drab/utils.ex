defmodule Drab.Utils do
  @moduledoc """
  Various Utilities

  """

import Drab.Core

  @doc """
  Encode a value in a JSON/Base64 format.

  Useful if you need to store values with comma, semicolon, quotes or Elixir data structures in a cookie, 
  or when you need to pass complex arguments to an Drab event handler call in a HTML template.

  ### Options

  * `encode` - `Boolean`, Encode in JSON/Base64, default `true`
  * `encrypt` - `Boolean`, Encrypt the value, default `false`. When `true`, implies `encode` = `true`

  Examples:

  pass an Elixir struct as the argument of an event handler call in a HTML template

    *file `my_page.html.drab`*

      <% encoded_value = Drab.Utils.encode_param %{question: "foo", answer: 42} %>
      <button drab='click:check_answer("<%= encoded_value %>")'>Check answer</button>

  then, on the server side, you can decode the value with the counterpart `decode_value` function:

    *file `my_commander.ex`*

      defhandler check_answer(socket, sender, value) do
        decoded_value = Drab.Utils.decode_value(value)
        
        question = decoded_value["question"]
        answer = decoded_value["answer"]

      end
  """
  def encode_value(value, options \\ []) do
    # Options
    encode = Keyword.get(options, :encode, true)
    encrypt = Keyword.get(options, :encrypt, false)

    value
    |> (&((encode || encrypt) && encode_js(&1) || &1)).()
    |> (&(encrypt && encrypt_value(&1, options) || &1)).()
    |> (&((encode || encrypt) && Base.encode64(&1, padding: false) || &1)).()
  end

  @doc """
  Decode a value encoded with encode_value/2

  ### Options

  * `decode` - `Boolean`, Decode JSON/Base64, default `true`
  * `decrypt` - `Boolean`, Decrypt the value, default `false`. When `true`, implies `decode` = `true`

  Examples:
        iex> Drab.Utils.decode_value("eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkISJ9")
        %{"message" => "Hello, World!"}
  """
  def decode_value(value, options \\ [])
  def decode_value(nil,  _options) do "" end
  def decode_value("",   _options) do "" end
  def decode_value(value, options) do
    # options
    decode = Keyword.get(options, :decode, true)
    decrypt = Keyword.get(options, :decrypt, false)

    value
    |> (&((decode || decrypt) && Base.decode64!(&1, padding: false) || &1)).()
    |> (&(decrypt && decrypt_value(&1, options) || &1)).()
    |> (&((decode || decrypt) && decode_js(&1) || &1)).()
  end

  defp encrypt_value(value, _options) do
    Drab.Live.Crypto.encrypt(value)
  end

  defp decrypt_value(value, _options) do
    Drab.Live.Crypto.decrypt(value)
  end

end # Module
