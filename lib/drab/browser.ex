defmodule Drab.Browser do
  import Drab.Core

  @moduledoc """
  Browser related functions.

  Provides information about connected browser, such as local datetime, user agent.
  """

  @now_js """
  var d = new Date();
  var retval = {
    year: d.getFullYear(),
    month: d.getMonth(),
    day: d.getDate(),
    hour: d.getHours(),
    minute: d.getMinutes(),
    second: d.getSeconds(),
    millisecond: d.getMilliseconds()
  };
  retval
  """

  defp js_to_naive_date(js_object) do
    NaiveDateTime.new(
      js_object["year"],
      # in the world of JS, February is a first month
      js_object["month"] + 1,
      js_object["day"],
      js_object["hour"],
      js_object["minute"],
      js_object["second"],
      {js_object["millisecond"] * 1000, 3}
    )
  end

  @doc """
  Returns string with the browser unique id.

  The id is generated on the client side and stored in local store.

      iex> Drab.Browser.id(socket)
      {:ok, "2bd34ffc-b365-46a9-9479-474b628364ed"}
  """
  @spec id(Phoenix.Socket.t()) :: {:ok | :error, String.t()}
  def id(socket) do
    case socket.assigns[:__client_id] do
      nil -> {:error, "can't get the browser id"}
      id -> {:ok, id}
    end
  end

  @doc """
  Returns string with the browser unique id.

  Bang version of `id/1`.
  """
  @spec id!(Phoenix.Socket.t()) :: String.t() | no_return
  def id!(socket) do
    case id(socket) do
      {:ok, id} -> id
      {:error, message} -> raise message
    end
  end

  @doc """
  Returns local browser time as NaiveDateTime. Timezone information is not included.

  Examples:

      iex> Drab.Browser.now(socket)
      {:ok, ~N[2017-04-01 15:07:57.027000]}
  """
  @spec now(Phoenix.Socket.t()) :: {Drab.Core.status(), NaiveDateTime.t()}
  def now(socket) do
    case exec_js(socket, @now_js) do
      {:ok, %{} = browser_now} -> js_to_naive_date(browser_now)
      other -> other
    end
  end

  @doc """
  Bang version of `now/1`. Raises exception on error.

  Examples:

      iex> Drab.Browser.now!(socket)
      ~N[2017-04-01 15:07:57.027000]
  """
  @spec now!(Phoenix.Socket.t()) :: NaiveDateTime.t()
  def now!(socket) do
    browser_now = exec_js!(socket, @now_js)

    case js_to_naive_date(browser_now) do
      {:ok, now} ->
        now

      _ ->
        raise """
        can't convert JS object to NaiveDateTime.

        #{inspect(browser_now)}
        """
    end
  end

  @offset_js "new Date().getTimezoneOffset()"

  @doc """
  Returns utc offset (the difference between local browser time and UTC time), in seconds.

  Examples:

      iex> Drab.Browser.utc_offset(socket)
      {:ok, 7200} # UTC + 02:00
  """
  @spec utc_offset(Phoenix.Socket.t()) :: Drab.Core.result()
  def utc_offset(socket) do
    case exec_js(socket, @offset_js) do
      {:ok, offset} -> {:ok, -60 * offset}
      other -> other
    end
  end

  @doc """
  Returns utc offset (the difference between local browser time and UTC time), in seconds.
  Raises exception on error.

  Examples:

      iex> Drab.Browser.utc_offset!(socket)
      7200 # UTC + 02:00
  """
  @spec utc_offset!(Phoenix.Socket.t()) :: integer
  def utc_offset!(socket) do
    -60 * exec_js!(socket, @offset_js)
  end

  @agent_js "navigator.userAgent"

  @doc """
  Bang version of `user_agent/1`.

  Examples:

      iex> Drab.Browser.user_agent!(socket)
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) ..."
  """
  @spec user_agent!(Phoenix.Socket.t()) :: String.t()
  def user_agent!(socket) do
    exec_js!(socket, @agent_js)
  end

  @doc """
  Returns browser information (userAgent).

  Examples:

      iex> Drab.Browser.user_agent(socket)
      {:ok, "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 ..."}
  """
  @spec user_agent(Phoenix.Socket.t()) :: Drab.Core.result()
  def user_agent(socket) do
    exec_js(socket, @agent_js)
  end

  @language_js "navigator.language"

  @doc """
  Bang version of `language/1`.

  Example:
      iex> Drab.Browser.language!(socket)
      "en-GB"
  """
  @spec language!(Phoenix.Socket.t()) :: String.t()
  def language!(socket) do
    exec_js!(socket, @language_js)
  end

  @doc """
  Returns browser language.

  Example:
      iex> Drab.Browser.language(socket)
      {:ok, "en-GB"}
  """
  @spec language(Phoenix.Socket.t()) :: Drab.Core.result()
  def language(socket) do
    exec_js(socket, @language_js)
  end

  @languages_js "navigator.languages"

  @doc """
  Bang version of `language/1`.

  Example:
      iex> Drab.Browser.languages!(socket)
      ["en-US", "en", "pl"]

  """
  @spec languages!(Phoenix.Socket.t()) :: list
  def languages!(socket) do
    exec_js!(socket, @languages_js)
  end

  @doc """
  Returns a list of browser supported languages.

  Example:
      iex> Drab.Browser.languages(socket)
      {:ok, ["en-US", "en", "pl"]}

  """
  @spec languages(Phoenix.Socket.t()) :: Drab.Core.result()
  def languages(socket) do
    exec_js(socket, @languages_js)
  end

  @doc """
  Exception raising version of redirect_to/2
  """
  @spec redirect_to!(Phoenix.Socket.t(), String.t()) :: any
  def redirect_to!(socket, url) do
    exec_js!(socket, "window.location = '#{url}'")
  end

  @doc """
  Redirects to the given url.

  WARNING: redirection will disconnect the current websocket, so it should be the last function
  launched in the handler.
  """
  @spec redirect_to(Phoenix.Socket.t(), String.t()) :: Drab.Core.result()
  def redirect_to(socket, url) do
    exec_js(socket, "window.location = '#{url}'")
  end

  @doc """
  Broadcast version of `redirect_to/2`.

  WARNING: redirection will disconnect the current websocket, so it should be the last function
  launched in the handler.
  """
  @spec broadcast_redirect_to(Phoenix.Socket.t(), String.t()) :: any
  def broadcast_redirect_to(socket, url) do
    broadcast_js(socket, "window.location = '#{url}'")
  end

  @doc """
  Exception raising version of console/2
  """
  @spec console!(Phoenix.Socket.t(), String.t()) :: Phoenix.Socket.t()
  def console!(socket, log) do
    exec_js!(socket, "console.log(#{Drab.Core.encode_js(log)})")
  end

  @doc """
  Sends the log to the browser console for debugging.
  """
  @spec console(Phoenix.Socket.t(), String.t()) :: Drab.Core.result()
  def console(socket, log) do
    exec_js(socket, "console.log(#{Drab.Core.encode_js(log)})")
  end

  @doc """
  Broadcasts the log to the browser consoles for debugging/
  """
  @spec broadcast_console(Phoenix.Socket.t(), String.t()) :: Drab.Core.bcast_result()
  def broadcast_console(socket, log) do
    broadcast_js(socket, "console.log(#{Drab.Core.encode_js(log)})")
  end

  @doc """
  Replaces the URL in the browser navigation bar for the given URL.

  The new URL can be absolute or relative to the current path. It must have the same origin as
  the current one.

      iex> Drab.Browser.set_url socket, "/servers/1"
      {:ok, nil}

      iex> Drab.Browser.set_url socket, "http://google.com/"
      {:error,
       "Failed to execute 'pushState' on 'History': A history state object ...'
        cannot be created in a document with origin 'http://localhost:4000' ..."}

  """
  @spec set_url(Phoenix.Socket.t(), String.t()) :: Drab.Core.result()
  def set_url(socket, url) do
    exec_js(socket, """
    window.history.pushState({}, "", #{Drab.Core.encode_js(url)});
    """)
  end

  @doc """
  Like `set_url/2`, but broadcasting the change to all connected browsers.
  """
  @spec broadcast_set_url(Phoenix.Socket.t(), String.t()) :: Drab.Core.bcast_result()
  def broadcast_set_url(socket, url) do
    broadcast_js(socket, """
    window.history.pushState({}, "", #{Drab.Core.encode_js(url)});
    """)
  end

  @doc """
  Exception throwing version of `set_url/2`.

      iex> Drab.Browser.set_url! socket, "/servers/1"
      nil

      iex> Drab.Browser.set_url! socket, "http://google.com/"
      ** (Drab.JSExecutionError) Failed to execute 'pushState' on 'History' ...

  """
  @spec set_url!(Phoenix.Socket.t(), String.t()) :: any
  def set_url!(socket, url) do
    exec_js!(socket, """
    window.history.pushState({}, "", #{Drab.Core.encode_js(url)});
    """)
  end

  @doc """
  Gets cookies from the browser.

  Returns map of `%{name => value}`. Notice that in case of the multiple cookies with the same name,
  returns only the one which browser returns first. It should be a cookie with the longest path.

  Cookie names are decoded using `Drab.Coder.URL`.

  Values are decoded using, by default, `Drab.Coder.URL`. You may change this by giving `:decoder`
  option:

      iex> Drab.Browser.cookies(socket, decoder: Drab.Coder.Cipher)
      {:ok, %{"exp" => 42, "mycookie" => "value"}}
  """
  @spec cookies(Phoenix.Socket.t(), Keyword.t()) :: Drab.Core.result()
  def cookies(socket, options \\ []) do
    decoder = options[:decoder] || Drab.Coder.URL

    case exec_js(socket, "document.cookie") do
      {:ok, cookies} -> {:ok, decode_cookies(cookies, decoder)}
      other -> other
    end
  end

  @doc """
  Exception raising version of `cookies/2`.
  """
  @spec cookies!(Phoenix.Socket.t(), Keyword.t()) :: map | no_return
  def cookies!(socket, options \\ []) do
    Drab.JSExecutionError.result_or_raise(cookies(socket, options))
  end

  @doc """
  Gets a named cookie from the browser.

  Values are decoded using, by default, `Drab.Coder.URL`. You may change this by giving `:decoder`
  option:

      iex> Drab.Browser.set_cookie(socket, "mycookie", "42")
      {:ok, "mycookie=42"}
      iex> Drab.Browser.cookie(socket, "mycookie")
      {:ok, "42"}
  """
  @spec cookie(Phoenix.Socket.t(), String.t(), Keyword.t()) :: Drab.Core.result()
  def cookie(socket, name, options \\ []) do
    case cookies(socket, options) do
      {:ok, cookies} ->
          (c = Map.get(cookies, name)) && {:ok, c} || {:error, "Cookie #{inspect name} not found."}
      other ->
        other
    end
  end

  @doc """
  Exception raising version of `cookie/3`
  """
  @spec cookie!(Phoenix.Socket.t(), String.t(), Keyword.t()) :: any | no_return
  def cookie!(socket, name, options \\ []) do
    socket
    |> cookies!(options)
    |> Map.get(name)
    |> (&(&1) || raise "Cookie #{inspect name} not found.").()
  end

  @doc """
  Delete the named cookie.

      iex> Drab.Browser.set_cookie(socket, "mycookie", "42")
      {:ok, "mycookie=42"}
      iex> Drab.Browser.cookie(socket, "mycookie")
      {:ok, "42"}
      iex> Drab.Browser.delete_cookie(socket, "mycookie")
      {:ok, _}
      iex> Drab.Browser.cookie(socket, "mycookie")
      {:error, "Cookie \"mycookie\" not found."}
  """
  @spec delete_cookie(Phoenix.Socket.t(), String.t()) :: Drab.Core.result()
  def delete_cookie(socket, name) do
    set_cookie(socket, name, "", max_age: -1)
  end

  @doc """
  Exception raising version of `delete_cookie/2`
  """
  @spec delete_cookie!(Phoenix.Socket.t(), String.t()) :: String.t() | no_return
  def delete_cookie!(socket, name) do
    Drab.Browser.set_cookie!(socket, name, "", max_age: -1)
  end

  @spec decode_cookies(String.t(), atom) :: map
  defp decode_cookies("", _), do: %{}

  defp decode_cookies(cookies, decoder) do
    cookies =
      for cookie <- String.split(cookies, ";") do
        m = Regex.named_captures(~r/(?<name>\S+)=(?<value>.*)/, cookie)

        {
          Drab.Coder.URL.decode!(m["name"]),
          case decoder.decode(m["value"]) do
            {:ok, val} -> val
            _ -> m["value"]
          end
        }
      end

    # browser should put the most important cookie (longest path) at the begining of the string
    cookies = Enum.uniq_by(cookies, fn {k, _} -> k end)
    Enum.into(cookies, %{})
  end

  @doc """
  Sets the cookie.

  Cookie names are encoded using `Drab.Coder.URL`.

  Values are encoded using, by default, `Drab.Coder.URL`. You may change this by giving `:encoder`
  option. Notice that some encoders (`Drab.Coder.URL` and `Drab.Coder.Base64`) accept only
  string as an argument. To set the cookie with any term, use `Drab.Coder.String` or
  `Drab.Coder.Cipher`.

  Options:
    * `:encoder` (default `Drab.Coder.URL`) - encode the cookie value with the given coder
    * `:path`
    * `:domain` - must contain two dots, like ".example.org"
    * `:secure` - if true, cookie will be https only
    * `:max_age` - number of seconds for when a cookie will be deleted

  Returns `{:ok, cookie}` where `cookie` is the string returned by the browsers, or
  `{:error, reason}` if something goes wrong.

  To delete a cookie, set the `:max_age` to -1.

  Examples:

      iex> set_cookie(socket, "mycookie", "value")
      {:ok, "mycookie=value"}

      iex> set_cookie(socket, "mycookie", "value", max_age: 10)
      {:ok, "mycookie=value; expires=Thu, 19 Jul 2018 19:47:09 GMT"}

      iex(69)> set_cookie(socket, "mycookie", %{any: "term"}, max_age: 10, encoder: Drab.Coder.Cipher)
      {:ok, "mycookie=QTEyO...Yinr17vXhHQ; expires=Thu, 19 Jul 2018 19:48:53 GMT"}
  """
  @spec set_cookie(Phoenix.Socket.t(), String.t(), term, Keyword.t()) :: Drab.Core.result()
  def set_cookie(socket, name, value, options \\ []) do
    encoder = options[:encoder] || Drab.Coder.URL
    path = if options[:path], do: "; path=#{options[:path]}", else: ""
    domain = if options[:domain], do: "; domain=#{options[:domain]}", else: ""
    secure = if options[:secure], do: "; secure", else: ""
    seconds = options[:max_age] || false
    name = Drab.Coder.URL.encode!(name)
    value = encoder.encode!(value)

    js = """
    var t = "#{name}=#{value}";
    var seconds = #{seconds};
    if (typeof seconds === "number") {
        const today = new Date();
        today.setTime(today.getTime() + (seconds * 1000));
        t += "; expires=" + today.toGMTString();
    }
    t += "#{path}#{domain}#{secure}";
    document.cookie = t;
    """

    exec_js(socket, js)
  end

  @doc """
  Exception raising version of `set_cookie/4`.
  """
  @spec set_cookie!(Phoenix.Socket.t(), String.t(), term, Keyword.t()) :: String.t() | no_return
  def set_cookie!(socket, name, value, options \\ []) do
    Drab.JSExecutionError.result_or_raise(set_cookie(socket, name, value, options))
  end

## Web Storage

  @doc """
  Save item to Web Storage.

  Parameters:
    * `socket` - the Drab socket
    * `storage_kind` - an atom which specifies the way the data will persist in the browser, can be:
                      `:local`    persist data in the browser even when the browser is closed and reopened; 
                       `:session` persist in the browser for the current session only 
                                  (data is lost when the browser window/tab is closed);
    * `key` - a string with the name of the key for the associated data 
    * `data` - the data to be persisted
    * `options` - see Options 

  Returns `{:ok, nil}` after success, or
          `{:error, reason}` if something goes wrong.

  Data is encoded using, by default, `Drab.Coder.URL`. You may change this by giving `:encoder`
  option. Notice that some encoders (`Drab.Coder.URL` and `Drab.Coder.Base64`) accept only
  string as an argument. To any kind of data, use `Drab.Coder.String` or
  `Drab.Coder.Cipher`.

  Options:
    * `:encoder` (default `Drab.Coder.URL`) - encode the data with the given coder

  Examples:
      iex> Drab.Browser.set_web_storage_item(socket, :session, "Answer", 42)
      {:ok, nil}

      iex> data = [%{name: "John", age: 42}, %{name: "Paul", age: 20}]
      iex> Drab.Browser.set_web_storage_item(socket, :session, "Persons", data, encoder: Drab.Coder.Cipher)
      {:ok, nil}
  """
  @spec set_web_storage_item(Phoenix.Socket.t(), atom, String.t(), any, Keyword.t())
    :: Drab.Core.result()
  def set_web_storage_item(socket, storage_kind, key, data, options \\ [])
  def set_web_storage_item(socket, :local, key, data, options),
    do: do_set_web_storage_item(socket, :local, key, data, options)
  def set_web_storage_item(socket, :session, key, data, options),
    do: do_set_web_storage_item(socket, :session, key, data, options)

  @spec do_set_web_storage_item(Phoenix.Socket.t(), atom, String.t(), any, Keyword.t())
    :: Drab.Core.result()
  defp do_set_web_storage_item(socket, storage_kind, key, data, options) do
    encoder = options[:encoder] || Drab.Coder.URL

    case encoder.encode(data) do
      {:ok, encoded_data} ->
          Drab.Core.exec_js(socket, """
            window.#{web_storage_object(storage_kind)}.setItem("#{key}", "#{encoded_data}");
          """)
      other -> other
    end
  end

  @doc """
  Exception raising version of `do_set_web_storage_item/5`.
  """
  @spec set_web_storage_item!(Phoenix.Socket.t(), atom, String.t(), any, Keyword.t())
    :: nil | no_return
  def set_web_storage_item!(socket, storage_kind, key, data, options \\ [])
  def set_web_storage_item!(socket, :local, key, data, options),
    do: do_set_web_storage_item!(socket, :local, key, data, options)
  def set_web_storage_item!(socket, :session, key, data, options),
    do: do_set_web_storage_item!(socket, :session, key, data, options)

  @spec do_set_web_storage_item!(Phoenix.Socket.t(), atom, String.t(), any, Keyword.t())
    :: nil | no_return
  defp do_set_web_storage_item!(socket, storage_kind, key, data, options) do
    socket
    |> do_set_web_storage_item(storage_kind, key, data, options)
    |> Drab.JSExecutionError.result_or_raise()
  end

  @doc """
  Retrieve item from Web Storage

  Options:
  * `:decoder` (default `Drab.Coder.URL`) - decode the stored data with the given coder, default `Drab.Coder.URL`

  Returns `{:ok, data}` after success, or
          `{:error, reason}` if something goes wrong.

  Examples:
      # Save data encoded
      iex> data = [%{name: "John", age: 42}, %{name: "Paul", age: 20}]
      iex> Drab.Browser.set_web_storage_item(socket, :session, "Persons", data, encoder: Drab.Coder.Cipher)
      {:ok, nil}

      # Retrieve saved encoded data withoud decoding
      iex> Drab.Browser.get_web_storage_item(socket, :session, "Persons")
      {:ok,
       "QTEyOEdDTQ.rXEw18jR5uBgzn2PRTI8-WlwHq57tV815HKVwjhbItb__Vf20v_xnAjuJmY.FXdqERie8jE4PrOp.dpTVHCIUzE67uTwB7rDzGgrZPWi372b2_vJZDa3unWMaDTkKQuWidwq02JwskYkMOEXiTP8o5x8spszEzd8wG68.HkB4bKkdIVqBal-2F7z5pw"}

      # Retrieve and decode saved data
      iex> Drab.Browser.get_web_storage_item(socket, :session, "Persons", decoder: Drab.Coder.Cipher)
      {:ok, [%{age: 42, name: "John"}, %{age: 20, name: "Paul"}]}
  """
  @spec get_web_storage_item(Phoenix.Socket.t(), atom, String.t(), Keyword.t())
    :: Drab.Core.result()
  def get_web_storage_item(socket, storage_kind, key, options \\ [])
  def get_web_storage_item(socket, :local, key, options),
    do: do_get_web_storage_item(socket, :local, key, options)
  def get_web_storage_item(socket, :session, key, options),
    do: do_get_web_storage_item(socket, :session, key, options)

  @spec get_web_storage_item(Phoenix.Socket.t(), String.t(), String.t(), Keyword.t())
    :: Drab.Core.result()
  defp do_get_web_storage_item(socket, storage_kind, key, options) do
    decoder = options[:decoder] || Drab.Coder.URL

    socket
    |> exec_js("""
        window.#{web_storage_object(storage_kind)}.getItem("#{key}");
        """)
    |> case do
        {:ok, nil} -> {:error, "key #{inspect key} not found"}
        {:ok, data} -> decoder.decode(data)
        other -> other
      end
  end

  @doc """
  Exception raising version of `get_web_storage_item/4`.
  """
  @spec get_web_storage_item!(Phoenix.Socket.t(), atom, String.t(), Keyword.t())
    :: any | no_return
  def get_web_storage_item!(socket, storage_kind, key, options \\ [])
  def get_web_storage_item!(socket, :local, key, options),
    do: do_get_web_storage_item!(socket, :local, key, options)
  def get_web_storage_item!(socket, :session, key, options),
    do: do_get_web_storage_item!(socket, :session, key, options)

  @spec get_web_storage_item!(Phoenix.Socket.t(), String.t(), String.t(), Keyword.t())
    :: any | no_return
  defp do_get_web_storage_item!(socket, storage_kind, key, options) do
    socket
    |> get_web_storage_item(storage_kind, key, options)
    |> Drab.JSExecutionError.result_or_raise()
  end

  # Returns a string with the name of the Web Store object to use in the JS call
  @spec web_storage_object(atom)  :: String.t()
  defp web_storage_object(:local), do: "localStorage"
  defp web_storage_object(:session), do: "sessionStorage"

  @doc """
  Removes a localStorage item.

  Returns `{:ok, nil}` after successful action, and also when doesn't exist any item item associated with `key`

  Examples:

      iex> Drab.Browser.remove_web_storage_item(socket, "MyItem")
      {:ok, nil}
  """
  @spec remove_web_storage_item(Phoenix.Socket.t(), String.t()) :: Drab.Core.result()
  def remove_web_storage_item(socket, key) do
    exec_js(socket, """
        window.localStorage.removeItem("#{key}");
        """)
  end

  @doc """
  Exception raising version of `remove_web_storage_item/2`
  """
  @spec remove_web_storage_item!(Phoenix.Socket.t(), String.t()) :: nil | no_return
  def remove_web_storage_item!(socket, key) do
    socket
    |> remove_web_storage_item(key)
    |> Drab.JSExecutionError.result_or_raise()
  end

  @doc """
  Check check browser support for localStorage and sessionStorage.

  Returns `{:ok, true}` if supported, `{:ok, false}` otherwise, or `{:error, error}` on errors.

  Examples:

      iex> Drab.Browser.check_web_storage_support(socket)
      {:ok, true}
  """
  @spec check_web_storage_support(Phoenix.Socket.t()) :: Drab.Core.result()
  def check_web_storage_support(socket) do
    result =
      exec_js(socket, """
        typeof(Storage);
        """)
      case result do
        {:ok, "function"} -> {:ok, true}
        {:ok, "undefined"} -> {:ok, false}
        other -> other
      end
  end

  @doc """
  Exception raising version of check_web_storage_support/1

  Returns `true` if supported, `false` otherwise.
  """
  @spec check_web_storage_support!(Phoenix.Socket.t()) :: true | false | no_return
  def check_web_storage_support!(socket) do
    socket
    |> check_web_storage_support()
    |> Drab.JSExecutionError.result_or_raise()
  end

end
