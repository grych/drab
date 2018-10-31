defmodule DrabTestApp.Broadcast1Commander do
  @moduledoc false

  use Drab.Commander, modules: [Drab.Query, Drab.Modal, Drab.Element]

  onload(:page_loaded)
  onconnect(:connected)
  # broadcasting("my_topic")

  def page_loaded(socket) do
    socket
    |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")

    socket
    |> Drab.Query.insert(
      "<h5>Drab Broadcast Topic: #{__drab__().broadcasting |> inspect}</h5>",
      after: "#page_loaded_indicator"
    )

    p = inspect(socket.assigns.__drab_pid)
    pid_string = ~r/#PID<(?<pid>.*)>/ |> Regex.named_captures(p) |> Map.get("pid")
    socket |> Drab.Query.update(:text, set: pid_string, on: "#drab_pid")

    subscribe(socket, same_topic("my_topic"))
  end

  def connected(socket) do
    exec_js!(socket, "window.$ = jQuery")
    socket |> Drab.Query.update(:text, set: "", on: "#broadcast_out")
    # socket |> Drab.Query.update(:value, set: get_store(socket, :broadcast1_text), on: "#broadcast1_text")
    topic = get_store(socket, :broadcast1_text)
    Drab.Element.set_prop(socket, "#broadcast1_text", value: topic)
    subscribe(socket, same_topic(topic))
  end

  defhandler broadcast1(socket, dom_sender) do
    socket
    |> update!(:text, set: "Broadcasted Text to same url", on: "#broadcast_out")
    |> update!(:text, set: "Broadcasted", on: this!(dom_sender))
    |> update!(class: "btn-danger", set: "btn-success", on: this!(dom_sender))
  end

  defhandler text1_change(socket, sender) do
    put_store(socket, :broadcast1_text, sender.params["broadcast1_text"])
  end

  defhandler send_to_safari(_socket, _) do
    broadcast_prop same_topic("safari"), "#broadcast_out", innerText: "safari"
  end
  defhandler send_to_chrome(_socket, _) do
    broadcast_prop same_topic("chrome"), "#broadcast_out", innerText: "chrome"
  end
end
