defmodule DrabTestApp.IntegrationCase do
  use ExUnit.CaseTemplate

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

  def click_and_wait(button_id) do
    button = Hound.Helpers.Page.find_element(:id, button_id)
    button |> Hound.Helpers.Element.click()
    button |> wait_for_enable()
  end

  def standard_click_and_get_test(test_name) do
    click_and_wait("#{test_name}_button")
    out = Hound.Helpers.Page.find_element(:id, "#{test_name}_out")
    assert Hound.Helpers.Element.visible_text(out) == test_name        
  end

end
