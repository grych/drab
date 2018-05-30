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
      <button drab=drab='click:add_cart("<%= encoded_value %>")'>Check answer</button>

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

  @doc """
  Extract a specific cookie from cookies string.

  ### Parameters
  * `cookies` - The string that cotains the cookies
  * `key` - The name of the cookie to extract

  ### Options
   See the options for `decode_value`

  """
  def extract_cookie(cookies, key, options \\ [])
  def extract_cookie(_cookies, nil, _options) do "" end
  def extract_cookie(_cookies, "", _options) do "" end
  def extract_cookie(cookies, key,   options) do
    cookies
    |> extract_cookie_string(key)
    |> extract_cookie_value(key)
    |> decode_value(options)
  end

  @doc """
  Convert raw cookies string in a list of maps, where :key is the cookie name, and :value is the cookie value.

  As at this level it is not possible to know which are the cookies values that have be encoded, their values are the same as those in the original string.

  Examples:
        iex> Drab.Utils.extract_cookies_maps("_ga=GA1.1.12345.54321; _gid=GA1.1.12345.54321; map1=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0; _gat_gtag_UA_123ABC=1; cookiebar=CookieAllowed")
        [
          %{key: "_ga", value: "GA1.1.12345.54321"},
          %{key: "_gid", value: "GA1.1.12345.54321"},
          %{key: "map1", value: "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0"},
          %{key: "_gat_gtag_UA_123ABC", value: "1"},
          %{key: "cookiebar", value: "CookieAllowed"}
        ]
  """
  @spec extract_cookies_maps(String.t()) :: Keyword.t()
  def extract_cookies_maps(cookies) do
    Regex.scan(~r/(^|\s)(.*?)=(.*?)(;|$)/, cookies)
    |> case do
      [] -> []
      matches -> matches_to_maps(matches)
    end
  end

## Private Helpers

  defp matches_to_maps(matches) do
    Enum.map(matches, fn match ->
      case match do
        [_, _, key, value, _] -> %{key: key, value: value}
        _ -> %{}
      end
    end)
  end

  defp extract_cookie_string(cookies, key) do
    ~r/(#{key}=.+?)(;|$)/
    |> Regex.run(cookies)
    |> case do
        [_, value, _] -> value
        _ -> ""
      end
  end

  defp extract_cookie_value(cookie, key) do
    ~r/#{key}=(.*)/
    |> Regex.run(cookie)
    |> case do
        [_, value] -> value
        _ -> ""
      end
  end

  defp encrypt_value(value, _options) do
    Drab.Live.Crypto.encrypt(value)
  end

  defp decrypt_value(value, _options) do
    Drab.Live.Crypto.decrypt(value)
  end

end # Module
