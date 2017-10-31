defmodule Drab.Browser do
  import Drab.Core
  @moduledoc """
  Browser related functions.

  Provides information about connected browser, such as local datetime, user agent.
  """

  @doc false
  def now(socket) do
    Deppie.once "Drab.Browser.now/1 is depreciated, please use now!/1 instead"
    now!(socket)
  end

  @doc """
  Returns local browser time as NaiveDateTime. Timezone information is not included.

  Examples:

      iex> Drab.Browser.now!(socket)
      ~N[2017-04-01 15:07:57.027000]
  """
  def now!(socket) do
    js = """
    var d = new Date()
    var retval = {
      year: d.getFullYear(),
      month: d.getMonth(),
      day: d.getDate(),
      hour: d.getHours(),
      minute: d.getMinutes(),
      second: d.getSeconds(),
      millisecond: d.getMilliseconds()
    }
    retval
    """
    {:ok, browser_now} = exec_js(socket, js)
    {:ok, now} = NaiveDateTime.new(
      browser_now["year"],
      browser_now["month"] + 1, # in the world of JS, February is a first month
      browser_now["day"],
      browser_now["hour"],
      browser_now["minute"],
      browser_now["second"],
      browser_now["millisecond"] * 1000
      )
    now
  end

  @doc """
  Returns utc offset (the difference between local browser time and UTC time), in seconds.

  Examples:

      iex> Drab.Browser.utc_offset!(socket)
      7200 # UTC + 02:00
  """
  def utc_offset!(socket) do
    {:ok, offset} = exec_js(socket, "new Date().getTimezoneOffset()")
    -60 * offset
  end

  @doc false
  def utc_offset(socket) do
    Deppie.once "Drab.Browser.utc_offset/1 is depreciated, please use utc_offset!/1 instead"
    utc_offset!(socket)
  end

  @doc """
  Returns browser information (userAgent).

  Examples:

      iex> Drab.Browser.user_agent!(socket)
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) ..."
  """
  def user_agent!(socket) do
    {:ok, agent} = exec_js(socket, "navigator.userAgent")
    agent
  end

  @doc false
  def user_agent(socket) do
    Deppie.once "Drab.Browser.user_agent/1 is depreciated, please use user_agent!/1 instead"
    user_agent!(socket)
  end

  @doc """
  Returns browser language.

  Example:
      iex> Drab.Browser.language!(socket)
      "en-GB"

  """
  def language!(socket) do
    {:ok, lang} = exec_js(socket, "navigator.language")
    lang
  end

  @doc false
  def language(socket) do
    Deppie.once "Drab.Browser.language/1 is depreciated, please use language!/1 instead"
    language!(socket)
  end

  @doc """
  Returns a list of browser supported languages.

  Example:
      iex> Drab.Browser.languages!(socket)
      ["en-US", "en", "pl"]

  """
  def languages!(socket) do
    {:ok, langs} = exec_js(socket, "navigator.languages")
    langs
  end

  @doc false
  def languages(socket) do
    Deppie.once "Drab.Browser.languages/1 is depreciated, please use languages!/1 instead"
    languages!(socket)
  end

  @doc """
  Redirects to the given url.

  WARNING: redirection will disconnect the current websocket, so it should be the last function launched in the
  handler.
  """
  def redirect_to!(socket, url) do
    Deppie.warn """
      Drab.Live.redirect_to! (broadcasting version of redirect_to/1) has been renamed to broadcast_redirect_to!/1
      """
    {:ok, _} = exec_js(socket, "window.location = '#{url}'")
  end

  @doc false
  def redirect_to(socket, url) do
    Deppie.once "Drab.Browser.redirect_to/2 is depreciated, please use redirect_to!/2 instead"
    redirect_to!(socket, url)
  end

  @doc """
  Broadcast version of `redirect_to!`.

  WARNING: redirection will disconnect the current websocket, so it should be the last function launched in the
  handler.
  """
  def broadcast_redirect_to!(socket, url) do
    broadcast_js(socket, "window.location = '#{url}'")
  end

  @doc """
  Sends the log to the browser console for debugging.
  """
  def console!(socket, log) do
    Deppie.warn """
      Drab.Live.console (broadcasting version of console/1) has been renamed to broadcast_console!/1
      """
      # do_console(socket, log, &Drab.push/5)
      Drab.push(socket, self(), nil, "console", log: log)
    socket
  end

  @doc false
  def console(socket, log) do
    Deppie.once "Drab.Browser.console/2 is depreciated, please use console!/2 instead"
    console!(socket, log)
  end

  @doc """
  Broadcasts the log to the browser consoles for debugging/
  """
  def broadcast_console!(socket, log) do
    Drab.broadcast(socket, nil, "console", log: log)
    # do_console(socket, log, &Drab.broadcast/5)
  end

  @doc """
  Replaces the URL in the browser navigation bar for the given URL.

  The new URL can be absolute or relative to the current path. It must have the same origin as the current one.

      iex> Drab.Browser.set_url! socket, "/servers/1"
      {:ok, nil}

      iex> Drab.Browser.set_url! socket, "http://google.com/"
      {:error,
       "Failed to execute 'pushState' on 'History': A history state object with URL 'http://google.com/'
        cannot be created in a document with origin 'http://localhost:4000' and URL 'http://localhost:4000/'."}

  """
  def set_url!(socket, url) do
    exec_js socket, """
    window.history.pushState({}, "", #{Drab.Core.encode_js(url)});
    """
  end

  @doc """
  Like `set_url/2`, but broadcasting the change to all connected browsers.
  """
  def broadcast_set_url!(socket, url) do
    exec_js socket, """
    window.history.pushState({}, "", #{Drab.Core.encode_js(url)});
    """
  end

  @doc false
  def set_url(socket, url) do
    Deppie.once "Drab.Browser.set_url/2 is depreciated, please use set_url!/2 instead"
    set_url!(socket, url)
  end

  # defp do_console(socket, log, push_or_broadcast_function) do
  #   push_or_broadcast_function.(socket, self(), nil, "console", log: log)
  # end

end
