defmodule Drab.Browser do
  import Drab.Core
  @moduledoc """
  """

  def timezone_difference(socket) do
    execjs(socket, "new Date().getTimezoneOffset()")
  end

  def utc_now(socket) do
    browser_utc = execjs(socket, "new Date().toISOString()")
    {:ok, now, _offset} = DateTime.from_iso8601(browser_utc)
    now
  end

  def user_agent(socket) do
    execjs(socket, "navigator.userAgent")
  end
end
