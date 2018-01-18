defmodule DrabTestApp.ModalTest do
  # import Drab.Query
  # import Drab.Modal
  use DrabTestApp.IntegrationCase

  defp modal_index do
    modal_url(DrabTestApp.Endpoint, :modal)
  end

  setup do
    modal_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Modal" do
    defp open_modal(modal_name) do
      find_element(:id, "#{modal_name}_button") |> click()

      # wait for modal to appear
      Process.sleep(700)
      assert String.contains?(visible_page_text(), "Title")
      assert String.contains?(visible_page_text(), "Message")
    end

    defp check_if_closed() do
      # wait for modal to hide
      Process.sleep(700)
      refute String.contains?(visible_page_text(), "Title")
      refute String.contains?(visible_page_text(), "Message")
    end

    defp button_click_test(modal, button, expected) do
      open_modal(modal)
      find_element(:css, button) |> click()
      check_if_closed()

      # it should return {button, parameters}
      assert visible_text(find_element(:id, "#{modal}_out")) == expected
    end

    defp key_press_test(modal, key, expected) do
      open_modal(modal)
      send_keys(key)
      check_if_closed()

      assert visible_text(find_element(:id, "#{modal}_out")) == expected
    end

    test "basic modal with default OK button - click OK" do
      button_click_test("modal1", "#_drab_modal_button_ok", "{:ok, %{}}")
    end

    test "basic modal with default OK button - click CLOSE" do
      button_click_test("modal1", "button.close", "{:cancel, %{}}")
    end

    test "basic modal with default OK button - press ENTER" do
      key_press_test("modal1", :enter, "{:ok, %{}}")
    end

    test "basic modal with default OK button - press ESC" do
      key_press_test("modal1", :escape, "{:cancel, %{}}")
    end

    test "basic modal with timeout" do
      open_modal("modal2")
      Process.sleep(1600)
      check_if_closed()
    end

    test "modal with form" do
      open_modal("modal3")
      find_element(:name, "first") |> fill_field("First")
      find_element(:id, "second") |> fill_field("Second")
      # there is no difference which button we click, should return values from the form
      find_element(:css, "#_drab_modal_button_cancel") |> click()
      check_if_closed()

      assert visible_text(find_element(:id, "modal3_out")) ==
               "{:cancel, %{\"first\" => \"First\", \"second\" => \"Second\"}}"
    end

    test "modal with additional button" do
      open_modal("modal4")
      find_element(:id, "_drab_modal_button_addtional") |> click()
      check_if_closed()
      assert visible_text(find_element(:id, "modal4_out")) == "{:additional, %{}}"
    end
  end
end
