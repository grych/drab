defmodule DrabTestApp.PartialsController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  # use Drab.Controller

  require Logger

  def partials(conn, _params) do
    render(
      conn,
      "partials.html",
      live_partial1: "before",
      live_partial2: "before",
      button1_placeholder: "here be button"
    )
  end
end
