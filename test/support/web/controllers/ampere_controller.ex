defmodule DrabTestApp.AmpereController do
  @moduledoc false
  
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  require Logger

  def index(conn, _params) do
    users = ~w(Zdzisław Zofia Hendryk Stefan)
    render_live conn, "index.html", users: users, count: length(users)
  end

  def mini(conn, _params) do
    render_live conn, "mini.html", count: 42
  end

  defp render_live(conn, template, assigns) do
    r = render(conn, template, assigns)
    # IO.inspect(Phoenix.View.render_to_string DrabTestApp.AmpereView, "index.html", assigns)
    # IO.inspect r.assigns
    r
  end
end
