defmodule DrabTestApp.Router do
  @moduledoc false
  
  use DrabTestApp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DrabTestApp do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index, as: :index
    get "/tests/core", PageController, :core, as: :core
    get "/tests/query", QueryController, :query, as: :query
    get "/tests/modal", QueryController, :modal, as: :modal
    get "/tests/waiter", PageController, :waiter, as: :waiter
    get "/tests/browser", PageController, :browser, as: :browser

    get "/tests/broadcast1", Broadcast1Controller, :index, as: :broadcast1
    get "/tests/broadcast2", Broadcast2Controller, :index, as: :broadcast2
    get "/tests/broadcast2/different_url", Broadcast2Controller, :index, as: :different_url
    get "/tests/broadcast3", Broadcast3Controller, :index, as: :broadcast3
    get "/tests/broadcast4", Broadcast4Controller, :index, as: :broadcast4
    get "/tests/broadcast5", Broadcast5Controller, :index, as: :broadcast5

    get "/tests/live/mini", LiveController, :mini,  as: :mini
    get "/tests/live",      LiveController, :index, as: :live
    get "/tests/live/form", LiveController, :form, as: :form
    get "/tests/live/query",LiveQueryController, :index, as: :live_query
  end

  # Other scopes may use custom stacks.
  # scope "/api", DrabTestApp do
  #   pipe_through :api
  # end
end
