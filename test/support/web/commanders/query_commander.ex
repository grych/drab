defmodule DrabTestApp.QueryCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Query, Drab.Modal]

  onload :page_loaded

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
    # this is because we do not include jQuery to globals in the brunch-config.js
    exec_js! socket, "window.$ = jQuery"
  end

  ### Drab.Modal ###
  defp modal_out(socket, sender), do: select(socket, data: "modal", from: this(sender)) <> "_out"

  defp update_out(socket, sender, ret), do: 
    socket |> update(:text, set: inspect(ret), on: "##{modal_out(socket, sender)}")

  def show_modal1(socket, sender) do
    ret = socket |> alert("Title", "Message")
    update_out(socket, sender, ret) 
  end

  def show_modal2(socket, sender) do
    ret = socket |> alert("Title", "Message", timeout: 1500)
    update_out(socket, sender, ret) 
  end

  def show_modal3(socket, sender) do
    form = "Message<br><input name='first'><input id='second'>"
    ret = socket |> alert("Title", form, buttons: [ok: "OK", cancel: "CANCEL"])
    update_out(socket, sender, ret) 
  end

  def show_modal4(socket, sender) do
    ret = socket |> alert("Title", "Message", buttons: [additional: "Additional"])
    update_out(socket, sender, ret) 
  end

  def sender_test(socket, sender) do
    socket |> update(:text, set: is_number(sender["data"]["integer"]), on: "#data_test_div_out1")
    socket |> update(:text, set: is_binary(sender["data"]["string"]), on: "#data_test_div_out2")
  end

end
