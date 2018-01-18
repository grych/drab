defmodule DrabTestApp.LiveQueryController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  use Drab.Controller

  require Logger

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      color: "#ffeecc",
      href: "https://tg.pl/drab",
      link: "Drab Demo Page"
    )
  end
end
