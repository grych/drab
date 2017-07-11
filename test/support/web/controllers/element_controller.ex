defmodule DrabTestApp.ElementController do
  @moduledoc false
  
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end
end
