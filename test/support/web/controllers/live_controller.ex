defmodule DrabTestApp.LiveController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  use Drab.Controller

  require Logger

  @users ~w(Zdzisław Zofia Hendryk Stefan)

  def index(conn, _params) do
    render conn, "index.html", users: @users, count: length(@users), color: "#ffffff"
  end

  def form(conn, _params) do
    render conn, "form.html", text1: "text1 initial value", select1: "2", textarea1: "textarea initial value",
      out: %{}
  end

  def table(conn, _params) do
    render conn, "table.html", users: @users, link: "https://tg.pl/drab"
  end

  def mini(conn, _params) do
    # render_live conn, "mini.html", list: ["A", "B"]
    render conn, "mini.html", class1: "btn", class2: "btn-primary", full_class: "", hidden: false, label: "default",
      list: [97,98,99], map: %{a: 1, b: 2}, color: "#10ffff", link: "https://tg.pl/drab", count: 42,
      url: "elixirforum.com", width: nil, text: "<b>bold</b>", users: ~w(Zdzisław Zofia Hendryk Stefan)
  end

end
