defmodule Drab.Query do
  @moduledoc """
  Provides interface to DOM objects on the server side. You may query (`select`) or manipulate 
  (`update`, `insert`, `delete`) properties of the selected DOM object.
  General syntax:

      return = socket |> select(what, from: selector)
      socket |> update(what, set: new_value, on: selector)
      socket |> insert(what, into: selector)
      socket |> delete(what, from: selector)

  where:
  * socket - websocket used in connection
  * selector - string with a DOM selector
  * what - a representation of jQuery method; an atom (eg. :html, :val) or key/value pair (like attr: name).
    An atom will launch the corresponding jQuey function without any arguments (eg. `.html()`). Key/value
    pair will launch the method named as the key with arguments taken from its value, so `text: "some"` becomes
    `.text("some")`.

  See function descriptions for details.

  Object manipulation (`update`, `insert`, `delete`) functions always returns socket - be be piped. Query `select`
  returns list of found DOM object properties (list of htmls, values etc) or empty list.
  """

  require Logger

  @methods               ~w(html text val)a
  @methods_with_argument ~w(attr prop css data)a
  @insert_methods        ~w(before after prepend append)a

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
  Options:
  * from: "selector" - DOM selector which is queried
  * attr: "attribute" - DOM attribute
  * prop: "property" - DOM property
  * css: "css"
  * data: "data"

  Examples:
      name = socket |> select(:val, from: "#name") |> List.first
      font = socket |> select(css: "font", from: "#name") |> List.first()

  The first example above translates to javascript:

      $('name').map(function() {
        return $(this).val()
      }).toArray()

  Available methods: see @methods, @methods_with_argument
  """
  def select(socket, options)
  def select(socket, [{method, argument}, from: selector]) when method in @methods_with_argument do
    do_query(socket, selector, jquery_method(method, argument), :select)
  end
  def select(_socket, [{method, argument}, from: selector]) do
    wrong_query! selector, method, argument
  end
  @doc "See `Drab.Query.select/2`"
  def select(socket, method, options)
  def select(socket, method, from: selector) when method in @methods do
    do_query(socket, selector, jquery_method(method), :select)
  end
  def select(_socket, method, from: selector) do
    wrong_query! selector, method 
  end

  @doc """
  Sets the DOM object property corresponding to `method`. In case the method
  requires an argument (like `attr()`), it should be given as key/value pair: method_name: "argument".
  Options:
  * on: selector - DOM selector, on which the changes are made
  * attr: attribute - DOM attribute
  * prop: property - DOM property
  * class: class - class name to be changed
  * css: updates given css
  * data: updates data-* attribute
  * set: value - new value

  Examples:
      socket |> update(:text, set: "saved...", on: "#save_button")
      socket |> update(attr: "style", set: "width: 100%", on: ".progress-bar")

  Update can also switch the classes in DOM object (remove one and insert another):

      socket |> update(class: "btn-success", set: "btn-danger", on: "#save_button")

  Available methods: see @methods, @methods_with_argument, :class
  """
  def update(socket, options)
  def update(socket, [{method, argument}, set: value, on: selector]) when method in @methods_with_argument do
    do_query(socket, selector, jquery_method(method, argument, value), :update)
    socket
  end
  def update(socket, [class: from_class, set: to_class, on: selector]) do
    socket 
      |> insert(class: to_class, into: selector)
      |> delete(class: from_class, from: selector)
  end
  def update(_socket, [{method, argument}, {:set, _value}, {:on, selector}]) do
    wrong_query! selector, method, argument
  end

  @doc "See `Drab.Query.update/2`"
  def update(socket, method, options)
  def update(socket, method, set: value, on: selector) when method in @methods do
    do_query(socket, selector, jquery_method(method, value), :update)
    socket
  end
  def update(_socket, method, set: value, on: selector) do
    wrong_query! selector, method, value
  end

  
  # insert(html: '<b>htnm', before: selector)
  # insert(html: '<b>htnm', after: selector)

  @doc """
  Adds new node or class to the selected object.
  When 
  Options:
  * class: class - class name to be inserted
  * into: selector - class will be added to specified selector(s)

  Example:
      socket |> insert(class: "btn-success", into: "#button")
  """
  def insert(socket, options)
  def insert(socket, class: class, into: selector) do
    do_query(socket, selector, jquery_method(:addClass, class), :insert)
    socket
  end
  def insert(_socket, [{method, argument}, into: selector]) do
    wrong_query! selector, method, argument
  end
  @doc "See `Drab.Query.insert/2`"
  def insert(socket, html, [{method, selector}]) when method in @insert_methods do
    do_query(socket, selector, jquery_method(method, html), :insert)
    socket
  end
  def insert(_socket, html, [{method, selector}]) do
    wrong_query! html, method, selector
  end

  @doc """
  Removes nodes, classes or attributes from selected node.

  With selector and no options, removes it and all its children. With given `from: selector` option, removes only 
  the content, but element remains in the DOM tree. With options `class: class, from: selector` removes
  class from given node(s). Given option `prop: property` or `attr: attribute` it is able to remove 
  property or attribute from the DOM node.
  
  Options:
  * class: class - class name to be deleted
  * prop: property - property to be removed from selected node(s)
  * attr: attribute - attribute to be deleted from selected node(s)
  * from: selector - DOM selector

  Example:
      socket |> delete(".btn")       # remove all `.btn`
      socket |> delete(from: "code") # empty all `<code>`, but node remains
      socket |> delete(class: "btn-success", from: "#button")
  """
  def delete(socket, options)
  def delete(socket, from: selector) do
    do_query(socket, selector, jquery_method(:empty), :delete)
    socket
  end
  def delete(socket, class: class, from: selector) do
    do_query(socket, selector, jquery_method(:removeClass, class), :delete)
    socket
  end
  def delete(socket, [prop: property, from: selector]) do
    do_query(socket, selector, jquery_method(:removeProp, property), :delete)
  end
  def delete(socket, [attr: attribute, from: selector]) do
    do_query(socket, selector, jquery_method(:removeAttr, attribute), :delete)
  end
  def delete(_socket, [{method, argument}, from: selector]) do
    wrong_query! selector, method, argument
  end
  def delete(socket, selector) do
    do_query(socket, selector, jquery_method(:remove), :delete)
    socket
  end

  @doc """
  Execute given jQuery method on selector.

      socket |> execute(:click, "#mybutton")
      socket |> execute(trigger: "click", "mybutton")
  """
  def execute() do
    
  end

  @doc """
  Synchronously executes the given javascript on the client side and returns value
  """
  def execjs(socket, js) do
    Phoenix.Channel.push(socket, "execjs",  %{js: js, sender: tokenize(socket, self())})

    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  def tokenize(socket, pid) do
    myself = :erlang.term_to_binary(pid)
    Phoenix.Token.sign(socket, "sender", myself)
  end

  # Build and run general jQuery query
  defp do_query(socket, selector, method_jqueried, type) do
    execjs(socket, build_js(selector, method_jqueried, type))
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

  # TODO: move it to templates
  defp build_js(selector, method_javascripted, :select) do
    """
    $('#{selector}').map(function() {
      return $(this).#{method_javascripted}
    }).toArray()
    """
  end
  defp build_js(selector, method_javascripted, type) when type in ~w(update insert delete)a do
    """
    $('#{selector}').#{method_javascripted}.toArray()
    """
  end

  defp escape_value(value) when is_boolean(value),  do: "#{inspect(value)}"
  defp escape_value(value) when is_nil(value),      do: ""
  defp escape_value(value),                         do: "#{encode_js(value)}"

  def encode_js(value), do: Poison.encode!(value)

  defp wrong_query!(selector, method, arguments \\ nil) do
    raise """
    Drab does not recognize your query:
      selector:  #{inspect(selector)}
      method:    #{inspect(method)}
      arguments: #{inspect(arguments)}
    """
  end


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
