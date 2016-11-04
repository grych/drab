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

  @methods            [:html, :text, :val, :attr]
  @attribute_methods  [:attr, :prop]

  @doc """
  Finds the DOM object which triggered the event. To be used only in event handlers.

      def button_clicked(socket, dom_sender) do
        socket 
          |> update(this(dom_sender), :text, "alread clicked")
          |> update(this(dom_sender), :attr, "disabled", true)
      end        
  """
  def this(dom_sender) do
    "[drab-id=#{dom_sender["drab_id"]}]"
  end

  @doc """
  Returns an array of values get by issue `method` on selected DOM objects.

      name = select(socket, "#name", :val) |> List.first

  The example above translates to javascript:

      $('name').map(function() {
        return $(this).val()
      }).toArray()

  Available methods: see @methods
  """
  def select(socket, selector, method) when method in @methods do
    do_query(socket, selector, jquery_method(method))
  end

  @doc """
  Returns an array of attribute or property value by issuing `method` on selected DOM objects.

      style = select(socket, ".progress-bar", :attr, "style") |> List.first

  Available methods: see @attribute_methods
  """
  def select(socket, selector, method, attribute) when method in @attribute_methods do
    do_query(socket, selector, jquery_method(method, attribute))
  end


  @doc """
  Sets the DOM object property corresponding to `method`. 

      update(socket, "#save_button", :text, "saved...")

  Available methods: see @methods
  """
  def update(socket, selector, method, value) when method in @methods do
    do_query(socket, selector, jquery_method(method, value))
    socket
  end

  @doc """
  Switches classes in selected DOM objects.
    
      update(socket, "mybutton", :switchClass, "btn-danger", "btn-success")
  """
  def update(socket, selector, :class, from_class, to_class) do
    socket 
      |> insert(selector, :class, to_class)
      |> delete(selector, :class, from_class)
  end

  @doc """
  Updates attribute or property of selected objects.

      update(socket, "#button", :attr, "disabled", false)
  """
  def update(socket, selector, method, attribute, value) when method in @attribute_methods do
    do_query(socket, selector, jquery_method(method, attribute, value))
    socket
  end

  @doc """
  Adds class to the selected DOM objects.

      insert(socket, "#button", :class, "btn-success")
  """
  def insert(socket, selector, :class, class) do
    do_query(socket, selector, jquery_method(:addClass, class))
    socket
  end

  @doc """
  Removes class in the selected DOM objects.

      delete(socket, "#button", :class, "btn-success")
  """
  def delete(socket, selector, :class, class) do
    do_query(socket, selector, jquery_method(:removeClass, class))
    socket
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
