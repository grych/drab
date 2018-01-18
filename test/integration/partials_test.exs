defmodule DrabTestApp.PartialsTest do
  # import Drab.Live
  # import Drab.Element
  use DrabTestApp.IntegrationCase

  defp partials_index do
    partials_url(DrabTestApp.Endpoint, :partials)
  end

  setup do
    partials_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "button inserted with poke" do
      check_partial_before(1)
      click_and_wait("button1")
      check_partial(1)
    end

    test "button inserted with insert_html" do
      check_partial_before(1)
      click_and_wait("button2")
      check_partial(1)
    end

    test "button inserted with innerHTML" do
      check_partial_before(1)
      click_and_wait("button3")
      check_partial(1)
    end

    test "parial inserted with insert_html" do
      check_partial_before(2)
      click_and_wait("button4")
      check_partial(2)
    end

    test "parial inserted with innerHTML" do
      check_partial_before(4)
      click_and_wait("button5")
      check_partial(4)
    end
  end

  defp check_partial_before(i) do
    assert css_property({:id, "partial#{i}_color"}, "backgroundColor") == "rgba(170, 170, 187, 1)"
    assert String.contains?(inner_text({:id, "partial#{i}_color"}), "in partial#{i}")
    assert attribute_value({:id, "partial#{i}_href"}, "href") == "http://tg.pl/"
    assert inner_text({:id, "partial#{i}_href"}) == "http://tg.pl"
  end

  defp check_partial(i) do
    assert css_property({:id, "partial#{i}_color"}, "backgroundColor") == "rgba(255, 51, 34, 1)"
    assert String.contains?(inner_text({:id, "partial#{i}_color"}), "changed in commander")
    assert attribute_value({:id, "partial#{i}_href"}, "href") == "http://elixirforum.com/"
    assert inner_text({:id, "partial#{i}_href"}) == "http://elixirforum.com"
  end
end
