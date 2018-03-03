defmodule DrabTestApp.NodrabController do
  @moduledoc false

  use DrabTestApp.Web, :controller

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      nodrab: "this is not drabbed at all"
    )
  end
end
