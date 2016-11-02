defmodule Drab.Query do
  @moduledoc """
  Maps jQuery functions to Elixir functions. To be used in Drab.Commander.
  """

  # TODO: generate it in macro based on the list

  @doc """
  Use like jQuery $(this) in event handlers in commander.

      def button_clicked(socket, dom_sender) do
        socket 
          |> text(this(dom_sender), "alread clicked")
          |> prop(this(dom_sender), "disabled", true)
      end        
  """
  def this(dom_sender) do
    "[drab-id='#{dom_sender["drab_id"]}']"
  end

  @doc """
  Returns a list of values of jQuery $().html() on the client

    name = html(socket, "#name") |> List.first
  """
  def html(socket, query) do
    generic_query(socket, query, "html()")
  end

  @doc """
  Sets html of the DOM object by running $().html(value) on the client. Returns socket so it can be piped.

    html(socket, "#warning_div", "You must provide the username")
  """
  def html(socket, query, value) do
    generic_query(socket, query, "html(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Returns a list of values of jQuery $().text() on the client

    buttons = text(socket, "#save_button")
  """
  def text(socket, query) do
    generic_query(socket, query, "text()")
  end

  @doc """
  Sets text of the DOM object by running $().text(value) on the client. Returns socket so it can be piped.

    text(socket, "#save_button", "saved...")
  """
  def text(socket, query, value) do
    generic_query(socket, query, "text(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Returns a list of values of jQuery $().val() on the client

      inputs = val(socket, "input")
  """
  def val(socket, query) do
    generic_query(socket, query, "val()")
  end

  @doc """
  Sets value of the DOM object by running $().val(value) on the client. Returns socket so it can be piped.

      # clean up all inputs
      val(socket, "input", "")
  """
  def val(socket, query, value) do
    generic_query(socket, query, "val(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Returns a list of attributes of jQuery $().attr() on the client

      is_enabled = attr(socket, "#mybutton", "enabled") |> List.first()
  """
  def attr(socket, query, att) do
    generic_query(socket, query, "attr(#{Poison.encode!(att)})")
  end

  @doc """
  Sets attribute of the DOM object by running $().attr(value) on the client. Returns socket so it can be piped.

      attr(socket, "#button", "enabled", false)
  """
  def attr(socket, query, att, value) do
    generic_query(socket, query, "attr(#{Poison.encode!(att)}, #{escape_value(value)})")
    socket
  end

  @doc """
  Returns a list of properties of jQuery $().prop() on the client

      is_enabled = prop(socket, "#mybutton", "enabled") |> List.first()
  """
  def prop(socket, query, att) do
    generic_query(socket, query, "prop(#{Poison.encode!(att)})")
  end

  @doc """
  Sets property of the DOM object by running $().prop(value) on the client. Returns socket so it can be piped.

      prop(socket, "#button", "enabled", false)
  """
  def prop(socket, query, att, value) do
    generic_query(socket, query, "prop(#{Poison.encode!(att)}, #{escape_value(value)})")
    socket
  end

  @doc """
  Add a class to DOM object classes

      add_class(socket, "#mybutton", "btn-success")
  """
  def add_class(socket, query, value) do
    generic_query(socket, query, "addClass(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Remove a class from DOM object classes

      remove_class(socket, "#mybutton", "btn-success")
  """
  def remove_class(socket, query, value) do
    generic_query(socket, query, "removeClass(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Toggles class in DOM object classes. 

      toggle_class(socket, "#mybutton", "btn-success")
  """
  def toggle_class(socket, query, value) do
    generic_query(socket, query, "toggleClass(#{Poison.encode!(value)})")
    socket
  end

  @doc """
  Switches classes in DOM object.

      change_class(socket, "#mybutton", "btn-success", "btn-danger")
  """
  def change_class(socket, query, from_value, to_value) do
    add_class(socket, query, to_value)
    remove_class(socket, query, from_value)
    socket
  end

  defp generic_query(socket, query, get_function) do
    myself = :erlang.term_to_binary(self())
    sender = Phoenix.Token.sign(socket, "sender", myself)

    Phoenix.Channel.push(socket, "query",  %{query: query, sender: sender, get_function: get_function})
    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  defp escape_value(value) when is_boolean(value) do
    "#{inspect(value)}"
  end
  defp escape_value(value) do
    "#{Poison.encode!(value)}"
  end
end
