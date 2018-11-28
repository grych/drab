defmodule DrabTestApp.LiveCommander do
  @moduledoc false
  # import Phoenix.HTML

  use Drab.Commander, modules: [Drab.Live, Drab.Element, Drab.Modal]
  onload(:page_loaded)
  broadcasting(:same_action)
  access_session(:current_user_id)

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
    poke(socket, text: "set in the commander")
    put_store(socket, :current_user_id, 44)
    # socket.assigns.__drab_index |> IO.inspect(label: "**SOCKET: ")
    # exec_js(socket, "navigator.geolocation.watchPosition(function(pos){Drab.exec_elixir('position_changed', {\"lat\":pos.coords.latitude, \"lon\": pos.coords.longitude, \"drab\": __drab.index});}, function(err){}, {});", timeout: 1000)
  end

  defhandler position_changed(socket, payload) do
    payload |> IO.inspect(label: "payload")
    socket.assigns.__drab_index |> IO.inspect(label: "__drab_index: ")
  end

  defhandler update_both(socket, _) do
    poke(socket, users: ["Mieczysław", "Andżelika", "Brajanek"], count: 3, color: "#66FFFF")
  end

  defhandler update_count(socket, _) do
    poke(socket, count: 3)
  end

  defhandler update_list(socket, _) do
    poke(socket, users: ["Mieczysław", "Andżelika", "Brajanek"])
  end

  defhandler update_in_partial1(socket, _) do
    poke(
      socket,
      "partial1.html",
      in_partial: "updated partial 1",
      color: "#66FFFF",
      link: "https://tg.pl/drab"
    )
  end

  defhandler update_in_partial2(socket, _) do
    poke(
      socket,
      DrabTestApp.Live2View,
      "partial2.html",
      in_partial: "updated partial 2",
      color: "#FF6666",
      link: "https://tg.pl/drab/live"
    )
  end

  defhandler update_in_partial2_bad(socket, _) do
    poke(
      socket,
      "partial2.html",
      in_partial: "updated partial 2",
      color: "#FF6666",
      link: "https://tg.pl/drab/live"
    )
  end

  defhandler update_in_partial3(socket, _) do
    poke(socket, "partial3.html", in_partial: "updated partial 3", link: "https://tg.pl/")
  end

  defhandler update_in_main_partial(socket, _) do
    poke(socket, color: "#aabbcc")
  end

  defhandler update_in_subpartial(socket, _) do
    poke(socket, "subfolder/subpartial.html", text: "UPDATED")
  end

  defhandler update_form(socket, sender) do
    poke(socket, out: sender.params)
  end

  defhandler update_link(socket, _) do
    poke(socket, link: "https://elixirforum.com")
  end

  defhandler add_item(socket, sender) do
    items = peek!(socket, :list)
    new_item = sender["form"]["drab[new_item]"]
    new_list = items ++ ["#{new_item}"]
    Drab.Live.poke(socket, list: new_list)
  end


  defhandler shorten_url(socket, _sender) do
    # IO.inspect sender.params["long_url_textarea"]
    poke(socket, shorten_url: "SHORT", long_url: "LONG")
  end

  defhandler update_mini(socket, _sender) do
    Process.sleep(2000)
    poke(socket, text: "changed")
  end

  defhandler update_mini(socket, _sender, argument) when is_integer(argument) do
    poke(socket, text: "integer")
  end

  defhandler update_mini(socket, _sender, argument) when is_binary(argument) do
    poke(socket, text: "any")
  end

  defhandler update_users(socket, _sender) do
    poke(socket, users: ["Mirmił", "Hegemon", "Kokosz", "Kajko"])
  end

  defhandler update_excluded_and_users(socket, _sender) do
    poke(socket, users: peek!(socket, :users), excluded: "Hegemon")
  end

  defhandler update_excluded(socket, _sender) do
    poke(socket, excluded: "Hegemon")
  end

  defhandler broadcast(socket, _sender) do
    broadcast_poke(socket, text: "broadcasted")
  end

  defhandler show_modal(socket, _sender) do
    title = "TEST"
    time = Time.utc_now |> Time.to_string
    body = render_to_string("_custom.html", time: time)
    buttons = [cancel: "Cancel", ok: "OK"]
    alert(socket, title, body, buttons: buttons)
  end

  defhandler test_update(socket, parameters) do
     set_html(socket, "#my_time", Time.utc_now |> Time.to_string)
     set_html(socket, "#my_sender", "#{parameters["sender"]}")
  end

  defhandler test_update(socket, sender, parameters) do
    # IO.inspect "test_update/3"
     set_html(socket, "#my_sender", "#{parameters["sender"]}, value: #{sender["value"]}")
  end
end
