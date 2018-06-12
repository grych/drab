defmodule Drab.Coder do
  @moduledoc """
  Provides various encoders/decoders to store values in the string.

  Example:

      <% {:ok, encoded_value} = Drab.Coder.encode(%{question: "foo", answer: 42}) %>
      <button  drab='click:check_answer("<%= encoded_value %>")'>Check answer</button>

      defhandler check_answer(socket, sender, value) do
        {:ok, decoded_value} = Drab.Coder.decode(value)

        question = decoded_value[:question]
        answer = decoded_value[:answer]
      end

  The default encoder is `Drab.Coder.Cipher`, which encrypts any value and returns the base-64
  encoded string. You may change the default encoder with:

      config :drab, default_encoder: Drab.Coder.String

  Each encoder has two pairs of functions:
  * `encode/1` / `decode/1`, returning tuple `{:ok, result}`
  * `encode!/1` / `decode!/1`, returning the result

  The result of encode functions is always a string. The argument might be restricted to string
  (`Drab.Coder.URL`, `Drab.Coder.Base64`). Other encoders takes any valid term as an argument.

  The argument of decode functions is always a string.

  Available encoders:
  * `Drab.Coder.URL` - urlencode, encodes only string
  * `Drab.Coder.Base64` - simple base-64, encodes string only (no encryption)
  * `Drab.Coder.String` - encodes any term to string, not ciphered
  * `Drab.Coder.Cipher` - encodes any term to an encrypted string (default)

  You may use the encoders individually, they expose the same API as `Drab.Coder`:

      iex> {:ok, encoded} = Drab.Coder.String.encode(%{forty_two: 42})
      iex> Drab.Coder.String.decode(encoded)
      {:ok, %{forty_two: 42}}

  It is used in the other part of the application, for example in `Drab.Browser.set_cookie/3`:

      set_cookie(socket, "my_cookie", "42", encode: true) # use default encoder
      set_cookie(socket, "my_cookie", "result: 42", encode: Drab.Coder.URL)
  """

  @type return :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Encodes term to the string.

  Returns:
  * `{:ok, string}`
  * `{:error, reason}`

  Example:

      iex> {:ok, encoded} = Drab.Coder.encode(%{forty_two: 42})
      iex> is_binary(encoded)
      true
  """
  @spec encode(term) :: Drab.Coder.return()
  defdelegate encode(term), to: Drab.Config.get(:default_encoder)

  @doc """
  Bang version of `encode/1`.

  Returns string.

      iex> encoded = Drab.Coder.encode!(%{forty_two: 42})
      iex> is_binary(encoded)
      true
  """
  @spec encode!(term) :: String.t()
  defdelegate encode!(term), to: Drab.Config.get(:default_encoder)

  @doc """
  Decodes the string, returning the encoded value (any term).

  Returns:
  * `{:ok, term}`
  * `{:error, reason}`

  Example:

      iex> {:ok, encoded} = Drab.Coder.encode(%{forty_two: 42})
      iex> Drab.Coder.decode(encoded)
      {:ok, %{forty_two: 42}}
  """
  @spec decode(String.t()) :: Drab.Coder.return()
  defdelegate decode(string), to: Drab.Config.get(:default_encoder)

  @doc """
  Bang version of `decode/1`.

  Returns the term.

      iex> encoded = Drab.Coder.encode!(%{forty_two: 42})
      iex> Drab.Coder.decode!(encoded)
      %{forty_two: 42}
  """
  @spec decode!(String.t()) :: term
  defdelegate decode!(string), to: Drab.Config.get(:default_encoder)
end
