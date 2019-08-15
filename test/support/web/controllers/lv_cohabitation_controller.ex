defmodule DrabTestApp.LVCohabitationController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  require Logger

  def index_drab(conn, params) do
    render(conn, "index_drab.html", status: "unititialised", id: params["id"])
  end  

  def index_lv(conn, params) do
    live_render(conn, DrabTestApp.LVCohabitationLive , session: %{status: "unititialised", id: params["id"]})
  end
end
