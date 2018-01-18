defmodule DrabTestApp.Web do
  @moduledoc false

  def model do
    quote do
      # Define common model functionality
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      import DrabTestApp.Router.Helpers
      import DrabTestApp.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "test/support/web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import DrabTestApp.Router.Helpers
      import DrabTestApp.ErrorHelpers
      import DrabTestApp.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import DrabTestApp.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
