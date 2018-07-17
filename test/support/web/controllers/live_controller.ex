defmodule DrabTestApp.LiveController do
  @moduledoc false

  use DrabTestApp.Web, :controller
  # use Drab.Controller

  require Logger

  @users ~w(Zdzisław Zofia Hendryk Stefan)

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      users: @users,
      count: length(@users),
      color: "#ffffff",
      text: "set in the controller",
      nodrab1: "this is not drabbed",
      nodrab2: "this is not drabbed as well"
    )
  end

  def form(conn, _params) do
    render(
      conn,
      "form.html",
      text1: "text1 initial value",
      select1: "2",
      textarea1: "textarea initial value",
      out: %{},
      text: "set in the controller"
    )
  end

  def table(conn, _params) do
    render(
      conn,
      "table.html",
      users: @users,
      link: "https://tg.pl/drab",
      text: "set in the controller"
    )
  end

  def form_for(conn, _params) do
    render(
      conn,
      "form_for.html",
      list: ["From controller", "Also from controller"],
      text: "set in the controller"
    )
  end

  def advanced(conn, _params) do
    render(
      conn,
      "advanced.html",
      users: ["Mirmił", "Hegemon", "Kokosz"],
      excluded: "Kokosz",
      text: "set in the controller"
    )
  end

  def mini(conn, _params) do
    # render_live conn, "mini.html", list: ["A", "B"]
    conn = assign(conn, :current_user_id, 42)
    conn = put_session(conn, :current_user_id, 43)
    conn = put_session(conn, :user_id, 66)
    render(
      conn,
      "mini.html",
      class1: "btn",
      class2: "btn-primary",
      full_class: "",
      hidden: false,
      label: "default",
      list: [97, 98, 99],
      map: %{a: 1, b: 2},
      color: "#10ffff",
      link: "https://tg.pl/drab",
      count: 42,
      url: "elixirforum.com",
      width: nil,
      text: "<b>bold</b>",
      users: ~w(Zdzisław Zofia Hendryk Stefan),
      text: "set in the controller",
      user: "Zofia",
      in_partial: "in partial before",
      my_list: [],
      weekdays: ["Pon", "Wt", "Sr"],
      current_week_monday: "MONDAY",
      shorten_url: "short url",
      long_url: "long url"
    )
  end

  def broadcasting(conn, _param) do
    render(conn, text: "set in the controller")
  end
end
