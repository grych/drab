defmodule DrabTestApp.LiveForm do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  defp form_index do
    form_url(DrabTestApp.Endpoint, :form)
  end

  setup do
    form_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for the Drab to initialize
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "form should return initial values" do
      socket = drab_socket()
      assert peek(socket, :out) == %{}
      click_and_wait("update_form_button")
      assert peek(socket, :out) == %{"radio" => "2",
                                    "textarea" => "textarea initial value", 
                                    "select_input" => "2", 
                                    "text_input" =>  "text1 initial value"}
    end

    test "poking should update form" do
      socket = drab_socket()
      assert peek(socket, :out) == %{}
      poke socket, text1: "text1 updated value",
                   textarea1: "textarea updated value",
                   select1: 3
      click_and_wait("update_form_button")
      assert peek(socket, :out) == %{"radio" => "2",
                                    "textarea" => "textarea updated value", 
                                    "select_input" => "3", 
                                    "text_input" => "text1 updated value"}
    end

  end
end
