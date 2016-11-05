defmodule Drab.Query do
  @moduledoc """
  Provides interface to DOM objects on the client side. You may query (`select`) or manipulate 
  (`update`, `insert`, `delete`) properties of the selected DOM object.
  General syntax:

      return = select(socket, selector, property or jquery method, optional value1)
      update(socket, selector, property or jquery method, optional value1, optional value2)
      insert(socket, selector, property or jquery method, optional value1, optional value2)
      delete(socket, selector, property or jquery method, optional value1)

  where:
  * socket - websocket used in connection
  * selector - string with a DOM selector
  * property or jquery method - indicates which property of the DOM object to retrieve or manipulate. Must 
    correspond to jQuery method on the object, so to run `$(selector).text()`, the `select(socket, selector, :text)`
    should be used
  * optional value1 - in select queries used to give a name of the attribute to retrieve; in updates could be 
    a new value of the property or attribute name
  * optional value2 - only in update queries: stores the attribute value
  See functions descriptions for details.

  Object manipulation (`update`, `insert`, `delete`) functions always returns socket - be be piped. Query `select`
  returns list of found DOM object properties (list of htmls, values etc) or empty list.
  """

  require Logger

  @methods            [:html, :text, :val, :attr]
  @methods_with_argument  [:attr, :prop]

  @doc """
  Finds the DOM object which triggered the event. To be used only in event handlers.

      def button_clicked(socket, dom_sender) do
        socket
          |> update(:text, set: "alread clicked", on: this(dom_sender))
          |> update(attr: "disabled", set: true, on: this(dom_sender))
      end        
  """
  def this(dom_sender) do
    "[drab-id=#{dom_sender["drab_id"]}]"
  end

  @doc """
  Returns an array of values get by issue jQuery `method` on selected DOM objects. In case the method
  requires an argument (like `attr()`), it should be given as key/value pair: method_name: "argument".

      name = socket |> select(:val, from: "#name") |> List.first
      attr = socket |> select(attr: "style", from: "#name") |> List.first()

  The first example above translates to javascript:

      $('name').map(function() {
        return $(this).val()
      }).toArray()

  Available methods: see @methods, @methods_with_argument
  """


  def select(socket, method, [from: selector]) when method in @methods do
    do_query(socket, selector, jquery_method(method))
  end
  def select(_socket, method, [from: selector]) do
    wrong_query! selector, method 
  end
  def select(socket, [{method, argument}, {:from, selector}]) when method in @methods_with_argument do
    do_query(socket, selector, jquery_method(method, argument))
  end
  def select(_socket, [{method, argument}, {:from, selector}]) do
    wrong_query! selector, method, argument
  end

  @doc """
  Sets the DOM object property corresponding to `method`. In case the method
  requires an argument (like `attr()`), it should be given as key/value pair: method_name: "argument".

      socket |> update(:text, set: "saved...", on: "#save_button")
      socket |> update(attr: "style", set: "width: 100%", on: ".progress-bar")

  Update can also switch the classes in DOM object (remove one and insert another):

      socket |> update(class: "btn-success", set: "btn-danger", on: "#save_button")

  Available methods: see @methods, @methods_with_argument, :class
  """
  def update(socket, method, [set: value, on: selector]) when method in @methods do
    do_query(socket, selector, jquery_method(method, value))
    socket
  end
  def update(_socket, method, [set: value, on: selector]) do
    wrong_query! selector, method
  end

  def update(socket, [{method, argument}, {:set, value}, {:on, selector}]) when method in @methods_with_argument do
    do_query(socket, selector, jquery_method(method, argument, value))
    socket
  end
  def update(socket, [class: from_class, set: to_class, on: selector]) do
    socket 
      |> insert(class: to_class, to: selector)
      |> delete(class: from_class, from: selector)
  end
  def update(_socket, [{method, argument}, {:set, value}, {:on, selector}]) do
    wrong_query! selector, method, argument
  end

  # delete(class: 'klasa', from: selector)
  # insert(class: 'klasa', to: selector)
  
  # insert(html: '<b>htnm', before: selector)
  # insert(html: '<b>htnm', after: selector)

  @doc """
  Adds class to the selected DOM objects.

      socket |> insert(class: "btn-success", to: "#button")
  """
  def insert(socket, [class: class, to: selector]) do
    do_query(socket, selector, jquery_method(:addClass, class))
    socket
  end
  def insert(_socket, [class: class, to: selector]) do
    wrong_query! selector, :class, class
  end
  @doc """
  Removes class in the selected DOM objects.

      socket |> delete(class: "btn-success", from: "#button")
  """
  def delete(socket, [class: class, from: selector]) do
    do_query(socket, selector, jquery_method(:removeClass, class))
    socket
  end
  def delete(_socket, [class: class, from: selector]) do
    wrong_query! selector, :class, class
  end

  # Build and run general jQuery query
  defp do_query(socket, selector, method_jqueried) do
    myself = :erlang.term_to_binary(self())
    sender = Phoenix.Token.sign(socket, "sender", myself)

    Phoenix.Channel.push(socket, "execjs",  %{js: build_js(selector, method_jqueried), sender: sender})

    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  defp wrong_query!(selector, method, arguments \\ nil) do
    raise """
    Drab does not recognize your query:
      selector:  #{inspect(selector)}
      method:    #{inspect(method)}
      arguments: #{inspect(arguments)}
    """
  end

  defp jquery_method(method) do
    "#{method}()"
  end
  defp jquery_method(method, value) do
    "#{method}(#{escape_value(value)})"
  end
  defp jquery_method(method, attribute, value) do
    "#{method}(#{escape_value(attribute)}, #{escape_value(value)})"
  end

  defp build_js(selector, method) do
    """
    $('#{selector}').map(function() {
      return $(this).#{method}
    }).toArray()
    """
  end

  defp escape_value(value) when is_boolean(value),  do: "#{inspect(value)}"
  defp escape_value(value) when is_nil(value),      do: ""
  defp escape_value(value),                         do: "#{encode_js(value)}"

  defp encode_js(value), do: Poison.encode!(value)



  # @doc """
  # Returns a list of values of jQuery $().html() on the client

  #   name = html(socket, "#name") |> List.first
  # """
  # def html(socket, query) do
  #   generic_query(socket, query, "html()")
  # end

  # @doc """
  # Sets html of the DOM object by running $().html(value) on the client. Returns socket so it can be piped.

  #   html(socket, "#warning_div", "You must provide the username")
  # """
  # def html(socket, query, value) do
  #   generic_query(socket, query, "html(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Returns a list of values of jQuery $().text() on the client

  #   buttons = text(socket, "#save_button")
  # """
  # def text(socket, query) do
  #   generic_query(socket, query, "text()")
  # end

  # @doc """
  # Sets text of the DOM object by running $().text(value) on the client. Returns socket so it can be piped.

  #   text(socket, "#save_button", "saved...")
  # """
  # def text(socket, query, value) do
  #   generic_query(socket, query, "text(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Returns a list of values of jQuery $().val() on the client

  #     inputs = val(socket, "input")
  # """
  # def val(socket, query) do
  #   generic_query(socket, query, "val()")
  # end

  # @doc """
  # Sets value of the DOM object by running $().val(value) on the client. Returns socket so it can be piped.

  #     # clean up all inputs
  #     val(socket, "input", "")
  # """
  # def val(socket, query, value) do
  #   generic_query(socket, query, "val(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Returns a list of attributes of jQuery $().attr() on the client

  #     is_enabled = attr(socket, "#mybutton", "enabled") |> List.first()
  # """
  # def attr(socket, query, att) do
  #   generic_query(socket, query, "attr(#{Poison.encode!(att)})")
  # end

  # @doc """
  # Sets attribute of the DOM object by running $().attr(value) on the client. Returns socket so it can be piped.

  #     attr(socket, "#button", "enabled", false)
  # """
  # def attr(socket, query, att, value) do
  #   generic_query(socket, query, "attr(#{Poison.encode!(att)}, #{escape_value(value)})")
  #   socket
  # end

  # @doc """
  # Returns a list of properties of jQuery $().prop() on the client

  #     is_enabled = prop(socket, "#mybutton", "enabled") |> List.first()
  # """
  # def prop(socket, query, att) do
  #   generic_query(socket, query, "prop(#{Poison.encode!(att)})")
  # end

  # @doc """
  # Sets property of the DOM object by running $().prop(value) on the client. Returns socket so it can be piped.

  #     prop(socket, "#button", "enabled", false)
  # """
  # def prop(socket, query, att, value) do
  #   generic_query(socket, query, "prop(#{Poison.encode!(att)}, #{escape_value(value)})")
  #   socket
  # end

  # @doc """
  # Add a class to DOM object classes

  #     add_class(socket, "#mybutton", "btn-success")
  # """
  # def add_class(socket, query, value) do
  #   generic_query(socket, query, "addClass(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Remove a class from DOM object classes

  #     remove_class(socket, "#mybutton", "btn-success")
  # """
  # def remove_class(socket, query, value) do
  #   generic_query(socket, query, "removeClass(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Toggles class in DOM object classes. 

  #     toggle_class(socket, "#mybutton", "btn-success")
  # """
  # def toggle_class(socket, query, value) do
  #   generic_query(socket, query, "toggleClass(#{Poison.encode!(value)})")
  #   socket
  # end

  # @doc """
  # Switches classes in DOM object.

  #     change_class(socket, "#mybutton", "btn-success", "btn-danger")
  # """
  # def change_class(socket, query, from_value, to_value) do
  #   add_class(socket, query, to_value)
  #   remove_class(socket, query, from_value)
  #   socket
  # end

  # defp generic_query(socket, query, get_function) do
  #   myself = :erlang.term_to_binary(self())
  #   sender = Phoenix.Token.sign(socket, "sender", myself)

  #   Phoenix.Channel.push(socket, "query",  %{query: query, sender: sender, get_function: get_function})
  #   receive do
  #     {:got_results_from_client, reply} ->
  #       reply
  #   end
  # end

end
