defmodule DrabTestApp.PartialsCommander do
  @moduledoc false

  use Drab.Commander, modules: [Drab.Live, Drab.Element]
  onload(:page_loaded)

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)

    # Process.sleep(100)

    poke(
      socket,
      live_partial1:
        render_to_string(
          DrabTestApp.LiveView,
          "partial1.html",
          in_partial: "in partial1",
          color: "#aaaabb",
          link: "http://tg.pl"
        )
    )

    poke(socket, button1_placeholder: button(1))

    insert_html(socket, "#button2_placeholder", :beforebegin, button(2))

    set_prop(socket, "#button3_placeholder", innerHTML: button(3))

    partial2 =
      render_to_string(
        DrabTestApp.Live2View,
        "partial2.html",
        in_partial: "in partial2",
        color: "#aaaabb",
        link: "http://tg.pl"
      )

    insert_html(socket, "#partial2_placeholder", :beforeend, partial2)

    partial4 =
      render_to_string(
        DrabTestApp.LiveView,
        "partial4.html",
        in_partial: "in partial4",
        color: "#aaaabb",
        link: "http://tg.pl"
      )

    set_prop(socket, "#partial4_placeholder", innerHTML: partial4)
    # poke socket, live_partial2: partial2
  end

  defp button(i), do: "<button id='button#{i}' drab-click='change_partial1'>Change partial1</button>"

  def change_partial1(socket, _sender) do
    poke(
      socket,
      DrabTestApp.LiveView,
      "partial1.html",
      in_partial: "changed in commander",
      link: "http://elixirforum.com",
      color: "#ff3322"
    )
  end

  def change_partial2(socket, _sender) do
    poke(
      socket,
      DrabTestApp.Live2View,
      "partial2.html",
      in_partial: "changed in commander",
      link: "http://elixirforum.com",
      color: "#ff3322"
    )
  end

  def change_partial4(socket, _sender) do
    poke(
      socket,
      DrabTestApp.LiveView,
      "partial4.html",
      in_partial: "changed in commander",
      link: "http://elixirforum.com",
      color: "#ff3322"
    )
  end
end
