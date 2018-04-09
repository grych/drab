defmodule DrabTestApp.ShareController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  use Drab.Controller, commanders: [DrabTestApp.Shared1Commander, DrabTestApp.Shared2Commander]

  def index(conn, _params) do
    render(conn, "index.html", text: "assigned in controller", color: "#ff2222", bgcolor: "#dddddd")
  end
end
