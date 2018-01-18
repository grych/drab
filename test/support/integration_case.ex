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
      Process.sleep(100)
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

  def add_page_loaded_indicator(socket) do
    js = """
    var begin = document.getElementById("begin")
    var txt = document.createTextNode("Page Loaded")
    var elem = document.createElement("h3")
    elem.appendChild(txt)
    elem.setAttribute("id", "page_loaded_indicator");
    begin.parentNode.insertBefore(elem, begin.nextElementSibling)
    """

    {:ok, _} = Drab.Core.exec_js(socket, js)
  end

  def add_pid(socket) do
    p = inspect(socket.assigns.__drab_pid)
    pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")

    js = """
    var pid = document.getElementById("drab_pid")
    var txt = document.createTextNode("#{pid_string}")
    pid.appendChild(txt)
    """

    {:ok, _} = Drab.Core.exec_js(socket, js)
  end
end
