defmodule DrabTestApp.IntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  use Hound.Helpers

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
    if element |> element_enabled? do
      :ok
    else 
      Process.sleep 100
      wait_for_enable(element)
    end
  end

  def click_and_wait(button_id) do
    button = find_element(:id, button_id)
    button |> click()
    button |> wait_for_enable()
  end

  def standard_click_and_get_test(test_name) do
    click_and_wait("#{test_name}_button")
    out = find_element(:id, "#{test_name}_out")
    assert visible_text(out) == test_name        
  end

  defp drab_pid() do
    pid = find_element(:id, "drab_pid") |> visible_text
    :erlang.list_to_pid('<#{pid}>')
  end

  def drab_socket() do
    Drab.get_socket(drab_pid())
  end

  # removes hash from the begin of #selector
  def nohash(selector) do
    String.replace_leading(selector, "#", "")
  end
end
