defmodule DrabTestApp.LiveController do
  @moduledoc false
  
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  require Logger

  def index(conn, _params) do
    users = ~w(Zdzisław Zofia Hendryk Stefan)
    render_live conn, "index.html", users: users, count: length(users)
  end

  def mini(conn, _params) do
    # render_live conn, "mini.html", list: ["A", "B"]
    render_live conn, "mini.html", class1: "btn", class2: "btn-primary", full_class: "", hidden: false, label: "default",
      list: [1,2,3], map: %{a: 1, b: 2}, color: "blue"
  end

  defp render_live(conn, template, assigns) do
    r = render(conn, template, assigns)
    # IO.inspect(Phoenix.View.render_to_string DrabTestApp.LiveView, "index.html", assigns)
    # IO.inspect r.assigns
    r
  end
end
