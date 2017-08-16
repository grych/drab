defmodule DrabTestApp.PartialsController do
  @moduledoc false
  
  use DrabTestApp.Web, :controller
  use Drab.Controller 

  require Logger


  def partials(conn, _params) do
    render conn, "partials.html", live_partial1: "before",
      button1_placeholder: "here be button"
  end

end
