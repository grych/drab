defmodule DrabTestApp.QueryController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  # use Drab.Controller

  def query(conn, _params) do
    render(conn, "query.html")
  end

  def modal(conn, _params) do
    render(conn, "modal.html")
  end
end
