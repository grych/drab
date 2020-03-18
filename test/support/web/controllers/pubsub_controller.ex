defmodule DrabTestApp.PubsubController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html", status: "initilised", data: DrabTestApp.Backend.get_data())
  end
end
