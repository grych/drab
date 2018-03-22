defmodule DrabTestApp.NakedController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  use Drab.Controller, commanders: [DrabTestApp.LoneCommander]

  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
