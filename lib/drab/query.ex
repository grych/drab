defmodule Drab.Query do
  require Logger

  @methods               ~w(html text val)a
  @methods_with_argument ~w(attr prop css data)a
  @insert_methods        ~w(before after prepend append)a
  @broadcast             &Drab.Query.broadcastjs/2
  @no_broadcast          &Drab.Query.execjs/2

  @moduledoc """
  Provides interface to DOM objects on the server side. You may query (`select/2`) or manipulate 
  (`update/2`, `insert/2`, `delete/2`, `execute/2`) the selected DOM object.

  General syntax:

      return = socket |> select(what, from: selector)
      socket |> update(what, set: new_value, on: selector)
      socket |> insert(what, into: selector)
      socket |> delete(what, from: selector)
      socket |> execute(what, on: selector)

  where:
  * socket - websocket used in connection
  * selector - string with a DOM selector
  * what - a representation of jQuery method; an atom (eg. :html, :val) or key/value pair (like attr: name).
    An atom will launch the corresponding jQuey function without any arguments (eg. `.html()`). Key/value
    pair will launch the method named as the key with arguments taken from its value, so `text: "some"` becomes
    `.text("some")`.

  Object manipulation (`update/2`, `insert/2`, `delete/2`, `execute/2`) returns tuple {:ok, number_of_objects_affected}. 
  Query `select/2` returns list of found DOM object properties (list of htmls, values etc) or empty list when nothing 
  found.

  Select queries always refers to the page on which the event were launched. Data manipulation queries (`update/2`, 
  `insert/2`, `delete/2`, `execute/2`) changes DOM objects on this page as well, but they have a broadcast versions:
  `update!/2`, `insert!/2`, `delete!/2` and `execute!/2`, which works the same, but changes DOM on every currently 
  connected browsers, which has opened the same URL.
  """

  @doc """
  Finds the DOM object which triggered the event. To be used only in event handlers.

      def button_clicked(socket, dom_sender) do
        socket |> update(:text, set: "alread clicked", on: this(dom_sender))
        socket |> update(attr: "disabled", set: true, on: this(dom_sender))
      end        

  Do not use it with with broadcast functions (`Drab.Query.update!`, `Drab.Query.insert`, `Drab.Query.delete`, 
  `Drab.Query.execute!`), because it returns the *exact* DOM object. In case if you want to broadcast, use 
  `Drab.Query.this!/1` instead.

  """
  def this(dom_sender) do
    "[drab-id=#{dom_sender["drab_id"]}]"
  end

  @doc """
  Like `Drab.Query.this/1`, but returns CSS ID of the object, so it may be used with broadcasting functions.

      def button_clicked(socket, dom_sender) do
        socket |> update!(:text, set: "alread clicked", on: this!(dom_sender))
        socket |> update!(attr: "disabled", set: true, on: this!(dom_sender))
      end

  Raises exception when being used on the object without an ID.
  """
  def this!(dom_sender) do
    id = dom_sender["id"]
    unless id, do: raise """
    Try to use Drab.Query.this!/1 on DOM object without an ID:
    #{inspect(dom_sender)}
    """ 
    "##{id}"
  end

  @doc """
  Returns an array of values get by executing jQuery `method` on selected DOM objects. 

  In case the method requires an argument (like `attr()`), it should be given as key/value 
  pair: method_name: "argument".

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
    do_query(socket, selector, jquery_method(method, argument), :select, @no_broadcast)
  end
  def select(_socket, [{method, argument}, from: selector]) do
    wrong_query! selector, method, argument
  end

  @doc "See `Drab.Query.select/2`"
  def select(socket, method, options)
  def select(socket, method, from: selector) when method in @methods do
    do_query(socket, selector, jquery_method(method), :select, @no_broadcast)
  end
  def select(_socket, method, from: selector) do
    wrong_query! selector, method 
  end

  @doc """
  Sets the DOM object property corresponding to `method`. 

  In case when the method requires an argument (like `attr()`), it should be given as key/value pair: 
  method_name: "argument".
  
  Waits for the browser to finish the changes and returns socket so it can be stacked.

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
  def update(socket, options) do
    do_update(socket, @no_broadcast, options)
    socket
  end

  @doc "See `Drab.Query.update/2`"
  def update(socket, method, options) do
    do_update(socket, @no_broadcast, method, options)
    socket
  end

  @doc """
  Like `Drab.Query.update/2`, but broadcasts to all currently connected browsers, which have the same URL opened.

  Broadcast functions are asynchronous, do not wait for the reply from browsers, immediately return socket.
  """
  def update!(socket, options) do
    do_update(socket, @broadcast, options)
    # bang function does not return anything
    socket
  end

  @doc "See `Drab.Query.update!/2`"
  def update!(socket, method, options) do
    do_update(socket, @broadcast, method, options)
    socket
  end

  defp do_update(socket, broadcast, [{method, argument}, set: value, on: selector]) when method in @methods_with_argument do
    {:ok, do_query(socket, selector, jquery_method(method, argument, value), :update, broadcast)}
  end
  defp do_update(socket, broadcast, [class: from_class, set: to_class, on: selector]) do
    # the below does not work in 1.3
    # case broadcast do
    #   @broadcast ->
    #     socket 
    #       |> insert!(class: to_class, into: selector)
    #       |> delete!(class: from_class, from: selector)
    #   @no_broadcast ->
    #     socket
    #       |> insert(class: to_class, into: selector)
    #       |> delete(class: from_class, from: selector)
    # end
    # workaround:
    if broadcast == @broadcast do
      socket 
        |> insert!(class: to_class, into: selector)
        |> delete!(class: from_class, from: selector)
    else
      socket 
        |> insert(class: to_class, into: selector)
        |> delete(class: from_class, from: selector)
    end
  end
  defp do_update(_socket, _broadcast, [{method, argument}, {:set, _value}, {:on, selector}]) do
    wrong_query! selector, method, argument
  end

  defp do_update(socket, broadcast, method, set: value, on: selector) when method in @methods do
    {:ok, do_query(socket, selector, jquery_method(method, value), :update, broadcast)}
  end
  defp do_update(_socket, _broadcast, method, set: value, on: selector) do
    wrong_query! selector, method, value
  end


  @doc """
  Adds new node (html) or class to the selected object.

  Waits for the browser to finish the changes and returns socket so it can be stacked.
  
  Options:
  * class: class - class name to be inserted
  * into: selector - class will be added to specified selector(s)
  * before: selector - creates html before the selector
  * after: selector - creates html node after the selector
  * append: selector - adds html to the end of the selector (inside the selector)
  * prepend: selector - adds html to the beginning of the selector (inside the selector)

  Example:
      socket |> insert(class: "btn-success", into: "#button")
      socket |> insert("<b>warning</b>", before: "#pane")
  """
  def insert(socket, options) do
    do_insert(socket, @no_broadcast, options)
    socket
  end

  @doc "See `Drab.Query.insert/2`"
  def insert(socket, html, options) do
    do_insert(socket, @no_broadcast, html, options)
    socket
  end

  @doc """
  Like `Drab.Query.insert/2`, but broadcast to all currently connected browsers, which have the same URL opened.

  Broadcast functions are asynchronous, do not wait for the reply from browsers, immediately return socket.
  """
  def insert!(socket, options) do
    do_insert(socket, @broadcast, options)
    socket
  end

  @doc "See `Drab.Query.insert/2`"
  def insert!(socket, html, options) do
    do_insert(socket, @broadcast, html, options)
    socket
  end

  defp do_insert(socket, broadcast, class: class, into: selector) do
    {:ok, do_query(socket, selector, jquery_method(:addClass, class), :insert, broadcast)}
  end
  defp do_insert(_socket, _broadcast, [{method, argument}, into: selector]) do
    wrong_query! selector, method, argument
  end

  defp do_insert(socket, broadcast, html, [{method, selector}]) when method in @insert_methods do
    {:ok, do_query(socket, selector, jquery_method(method, html), :insert, broadcast)}
  end
  defp do_insert(_socket, _broadcast, html, [{method, selector}]) do
    wrong_query! html, method, selector
  end

  @doc """
  Removes nodes, classes or attributes from selected node.

  With selector and no options, removes it and all its children. With given `from: selector` option, removes only 
  the content, but element remains in the DOM tree. With options `class: class, from: selector` removes
  class from given node(s). Given option `prop: property` or `attr: attribute` it is able to remove 
  property or attribute from the DOM node.
  
  Waits for the browser to finish the changes and returns socket so it can be stacked.

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
  def delete(socket, options) do
    do_delete(socket, @no_broadcast, options)
    socket
  end

  @doc """
  Like `Dom.Query.delete/2`, but broadcasts to all currently connected browsers, which have the same URL opened.

  Broadcast functions are asynchronous, do not wait for the reply from browsers, immediately return `:sent`.
  """
  def delete!(socket, options) do
    do_delete(socket, @broadcast, options)
    socket
  end

  defp do_delete(socket, broadcast, from: selector) do
    {:ok, do_query(socket, selector, jquery_method(:empty), :delete, broadcast)}
  end
  defp do_delete(socket, broadcast, class: class, from: selector) do
    {:ok, do_query(socket, selector, jquery_method(:removeClass, class), :delete, broadcast)}
  end
  defp do_delete(socket, broadcast, [prop: property, from: selector]) do
    {:ok, do_query(socket, selector, jquery_method(:removeProp, property), :delete, broadcast)}
  end
  defp do_delete(socket, _broadcast, [attr: attribute, from: selector]) do
    delete(socket, [prop: attribute, from: selector])
  end
  defp do_delete(_socket, _broadcast, [{method, argument}, from: selector]) do
    wrong_query! selector, method, argument
  end
  defp do_delete(socket, broadcast, selector) do
    {:ok, do_query(socket, selector, jquery_method(:remove), :delete, broadcast)}
  end

  @doc """
  Execute given jQuery method on selector. To be used in case built-in method calls are not enough.

  Waits for the browser to finish the changes and returns socket so it can be stacked.

      socket |> execute(:click, on: "#mybutton")
      socket |> execute(trigger: "click", on: "#mybutton")
      socket |> execute("trigger(\"click\")", on: "#mybutton")
  """
  def execute(socket, options) do
    do_execute(socket, @no_broadcast, options)
    socket
  end

  @doc """
  See `Drab.Query.execute/2`
  """
  def execute(socket, method, options) do
    do_execute(socket, @no_broadcast, method, options)
    socket
  end

  @doc """
  Like `Drab.Query.execute/2`, but broadcasts to all currently connected browsers, which have the same URL opened.

  Broadcast functions are asynchronous, do not wait for the reply from browsers, immediately return `:sent`.
  """
  def execute!(socket, options) do
    do_execute(socket, @broadcast, options)
    socket
  end

  @doc """
  See `Drab.Query.execute!/2`
  """
  def execute!(socket, method, options) do
    do_execute(socket, @broadcast, method, options)
    socket
  end

  defp do_execute(socket, broadcast, [{method, parameter}, {:on, selector}]) do
    {:ok, do_query(socket, selector, jquery_method(method, parameter), :execute, broadcast)}
  end

  defp do_execute(socket, broadcast, method, on: selector) when is_atom(method) do
    # execute(socket, jquery_method(method), selector)
    {:ok, do_query(socket, selector, jquery_method(method), :execute, broadcast)}
  end
  defp do_execute(socket, broadcast, method, on: selector) when is_binary(method) do
    {:ok, do_query(socket, selector, method, :execute, broadcast)}
  end

  @doc """
  Synchronously executes the given javascript on the client side and returns value.
  """
  def execjs(socket, js) do
    # Phoenix.Channel.push(socket, "execjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.push(socket, self(), "execjs", js: js)

    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  @doc """
  Asynchronously broadsasts given javascript to all browsers displaying current page.
  """
  def broadcastjs(socket, js) do
    # Phoenix.Channel.broadcast(socket, "broadcastjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.broadcast(socket, self(), "broadcastjs", js: js)
    socket
  end

  # Build and run general jQuery query
  defp do_query(socket, selector, method_jqueried, type, push_or_broadcast_function) do
    push_or_broadcast_function.(socket, build_js(selector, method_jqueried, type))
  end

  # defp do_query(socket, selector, method_jqueried, type, push_or_broadcast_function) do
  #   push_or_broadcast_function.(socket, build_js(selector, method_jqueried, type))
  # end

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
  defp build_js(selector, method_javascripted, type) when type in ~w(update insert delete execute)a do
    """
    $('#{selector}').#{method_javascripted}.toArray().length
    """
  end

  defp escape_value(value) when is_boolean(value),  do: "#{inspect(value)}"
  defp escape_value(value) when is_nil(value),      do: ""
  defp escape_value(value),                         do: "#{encode_js(value)}"

  @doc false
  def encode_js(value), do: Poison.encode!(value)

  defp wrong_query!(selector, method, arguments \\ nil) do
    raise """
    Drab does not recognize your query:
      selector:  #{inspect(selector)}
      method:    #{inspect(method)}
      arguments: #{inspect(arguments)}
    """
  end

end
