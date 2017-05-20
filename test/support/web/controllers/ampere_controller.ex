defmodule DrabTestApp.AmpereController do
  @moduledoc false
  
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  require Logger

  def index(conn, _params) do
    users = ~w(Zdzisław Zofia)
    render_live conn, "index.html", users: users, count: length(users)
  end

  defp render_live(conn, _template, assigns) do
    r = render(conn, "index.html", assigns)
    # IO.inspect(Phoenix.View.render_to_string DrabTestApp.AmpereView, "index.html", assigns)
    IO.inspect r.assigns
    r
  end
end
