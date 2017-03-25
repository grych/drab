defmodule DrabTestApp.PageController do
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  def index(conn, _params) do
    render conn, "index.html"
  end

  def core(conn, _params) do
    conn = put_session(conn, :test_session_value1, "test session value 1")
    conn = put_session(conn, :test_session_value2, "test session value 2")
    render conn, "core.html"
  end

  def query(conn, _params) do
    render conn, "query.html"
  end

end
