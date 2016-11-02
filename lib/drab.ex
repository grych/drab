defmodule Drab do
  @moduledoc """
  Drab allows to query and manipulate the browser DOM objext directly from the Phoenix server.

  Drab works with Phoenix Framework. To enable it on the specific page you must find its controller and 
  enable Drab by `use Drab.Controller` there:

      defmodule DrabExample.PageController do
        use Example.Web, :controller
        use Drab.Controller 

        def index(conn, _params) do
          render conn, "index.html"
        end
      end   

  Notice that it will enable Drab on all pages controlled by `DrabExample.PageController`.

  All Drab functions (callbacks and event handlers) should be placed in a module called 'commander'. It is very
  similar to controller, but it does not render any pages, instead it works with the live page. Each controller with 
  enabled Drab should have the corresponding commander.

      defmodule DrabExample.PageCommander do
        use Drab.Commander, onload: :page_loaded

        # Drab Callbacks
        def page_loaded(socket) do
          socket 
            |> html("div.jumbotron h2", "Welcome to Phoenix+Drab!")
            |> html("div.jumbotron p.lead", 
                    "Please visit <a href='https://tg.pl/drab'>Drab Proof-of-Concept</a> page for more examples and description")
        end

        # Drab Events
        def button_clicked(socket, dom_sender) do
          socket 
            |> text(this(dom_sender), "alread clicked")
            |> prop(this(dom_sender), "disabled", true)
        end

      end

  Events are defined directly in the HTML by adding `drab-` property:

      <button drab-click='button_clicked'>clickme</button>

  Clicking such button launches `DrabExample.PageCommander.button_clicked/2` on the Phoenix server.
  """

  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, socket}
  end

  def handle_cast({:onload, socket}, _) do
    # socket is coming from the first request from the client
    cmdr = commander(socket)
    onload = drab_config(cmdr).onload
    if onload do # only if onload exists
      apply(cmdr, onload, [socket])
    end
    {:noreply, socket}
  end

  # TODO: generate it with macro
  def handle_cast({:click, socket, %{"event_function" => evt_fun} = payload}, _) do
    do_handle_cast(socket, evt_fun, payload)
  end
  def handle_cast({:change, socket, %{"event_function" => evt_fun} = payload}, _) do
    do_handle_cast(socket, evt_fun, payload)
  end
  def handle_cast({:keyup, socket, %{"event_function" => evt_fun} = payload}, _) do
    do_handle_cast(socket, evt_fun, payload)
  end
  def handle_cast({:keydown, socket, %{"event_function" => evt_fun} = payload}, _) do
    do_handle_cast(socket, evt_fun, payload)
  end

  defp do_handle_cast(socket, evt_fun, payload) do
    # TODO: rethink the subprocess strategies - now it is just spawn_link
    spawn_link fn -> 
      apply(
        commander(socket), 
        String.to_atom(evt_fun), 
        [socket, Map.delete(payload, "event_function")]
      ) 
    end
    {:noreply, socket}
  end

  # returns the commander name for the given controller (assigned in token)
  defp commander(socket) do
    socket.assigns.controller.__drab__().commander
  end

  # if module is commander or controller with drab enabled, it has __drab__/0 function with Drab configuration
  defp drab_config(module) do
    module.__drab__()
  end
end
