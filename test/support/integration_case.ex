defmodule DrabTestApp.IntegrationCase do
  use ExUnit.CaseTemplate
  # use Hound.Helpers

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      use Hound.Helpers

      import DrabTestApp.Router.Helpers
      import DrabTestApp.IntegrationCase

      # The default endpoint for testing
      @endpoint DrabTestApp.Endpoint

      hound_session()
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def wait_for_enable(element) do
    if element |> Hound.Helpers.Element.element_enabled? do
      :ok
    else 
      Process.sleep 100
      wait_for_enable(element)
    end
  end
end
