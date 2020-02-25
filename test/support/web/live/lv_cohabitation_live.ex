defmodule  DrabTestApp.LVCohabitationLive do
  use Phoenix.LiveView

  def render(assigns) do
    DrabTestApp.LVCohabitationView.render("index_lv.html", assigns)
  end

  def mount(session, socket) do
    socket = 
     if id = session[:id] do
       socket
        |> assign(id: session.id)
        |> assign(status: "uninitialised")
      else
        socket
      end
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    socket =
      if id = params["id"] do
        socket
        |> assign(id: id)
        |> assign(status: "uninitialised")
      else
        socket
      end
    {:noreply, socket}
  end

end
