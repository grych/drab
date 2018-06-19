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

  @doc false
  @spec redirect_to!(Phoenix.Socket.t(), String.t()) :: any
  def redirect_to!(socket, url) do
    Deppie.warn("""
    Drab.Live.redirect_to! has been renamed to broadcast_redirect_to!/1
    """)

    broadcast_redirect_to(socket, url)
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

  @doc false
  @spec console!(Phoenix.Socket.t(), String.t()) :: Phoenix.Socket.t()
  def console!(socket, log) do
    Deppie.warn("""
    Drab.Live.console (broadcasting version of console/1) has been renamed to broadcast_console/1
    """)

    broadcast_console(socket, log)
    socket
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
end
