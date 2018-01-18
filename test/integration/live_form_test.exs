defmodule DrabTestApp.LiveFormTest do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  defp form_index do
    form_url(DrabTestApp.Endpoint, :form)
  end

  setup do
    form_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "form should return initial values" do
      socket = drab_socket()
      assert peek(socket, :out) == %{}
      click_and_wait("update_form_button")

      assert peek(socket, :out) == %{
               "radio" => "2",
               "textarea" => "textarea initial value",
               "select_input" => "2",
               "text_input" => "text1 initial value",
               "checkbox1" => "1"
             }
    end

    test "poking should update form" do
      socket = drab_socket()
      assert peek(socket, :out) == %{}

      poke(
        socket,
        text1: "text1 updated value",
        textarea1: "textarea updated value",
        select1: 3
      )

      Drab.Element.set_prop(socket, "input[name=radio][value='3']", checked: true)
      Drab.Element.set_prop(socket, "input[name=checkbox3][value='3']", checked: true)
      click_and_wait("update_form_button")

      assert peek(socket, :out) == %{
               "radio" => "3",
               "textarea" => "textarea updated value",
               "select_input" => "3",
               "text_input" => "text1 updated value",
               "checkbox1" => "1",
               "checkbox3" => "3"
             }
    end
  end
end
