defmodule Drab.Query do
  require Logger

  @methods               ~w(html text val width height innerWidth innerHeight outerWidth outerHeight position
                            offset scrollLeft scrollTop)a
  @methods_with_argument ~w(attr prop css data)a
  @insert_methods        ~w(before after prepend append)a
  @broadcast             &Drab.Core.broadcastjs/2
  @no_broadcast          &Drab.Core.execjs/2
  @html_modifiers        ~r/html|append|before|after|insertAfter|insertBefore|htmlPrefilter|prepend|replaceWidth|wrap/i

  @moduledoc """
  Drab module which provides interface to DOM objects on the server side. You may query (`select/2`) or manipulate 
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

  ## Events

  Events are defined directly in the HTML by adding `drab-event` and `drab-handler` properties:

      <button drab-event='click' drab-handler='button_clicked'>clickme</button>

  Clicking such button launches `DrabExample.PageCommander.button_clicked/2` on the Phoenix server.

  There are few shortcuts for the most popular events: `click`, `keyup`, `keydown`, `change`. For this event 
  an attribute `drab-EVENT_NAME` must be set. The following like is an equivalent for the previous one:

      <button drab-click='button_clicked'>clickme</button>

  Normally Drab operates on the user interface of the browser which generared the event, but it is possible to broadcast
  the change to all the browsers which are currently viewing the same page. See the bang functions in `Drab.Query` module.

  ## Event handler functions

  The event handler function receives two parameters:
  * `socket`     - the websocket used to communicate back to the page by `Drab.Query` functions
  * `dom_sender` - a map contains information of the object which sent the event; keys are binary strings

  The `dom_sender` map:

      %{
        "id"      => "sender object ID attribute",
        "name"    => "sender object 'name' attribute",
        "class"   => "sender object 'class' attribute",
        "text"    => "sender node 'text'",
        "html"    => "sender node 'html', result of running .html() on the node",
        "val"     => "sender object value",
        "data"    => "a map with sender object 'data-xxxx' attributes, where 'xxxx' are the keys",
        "event"   => "a map with choosen properties of `event` object"
        "drab_id" => "internal"
      }

  Example:

      def button_clicked(socket, dom_sender) do
        socket |> update(:text, set: "clicked", on: this(dom_sender))
      end

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
  Returns an array of values get by executing jQuery `method` on selected DOM object or objects. 
  Returns a Map of `%{ method => returns_of_methods}`, when the method is `:all`. 

  In case the method requires an argument (like `attr()`), it should be given as key/value 
  pair: method_name: "argument".

  Options:
  * from: "selector" - DOM selector which is queried
  * attr: "attribute" - DOM attribute
  * prop: "property" - DOM property
  * css: "css"
  * data: "att" - get "data-att" attribute

  Examples:
      name = socket |> select(:val, from: "#name") |> List.first
      # "Stefan"
      font = socket |> select(css: "font", from: "#name")
      # ["normal normal normal normal 14px / 20px \\"Helvetica Neue\\", Helvetica, Arial, sans-serif"]
      button_ids = socket |> select(data: "button_id", from: "button")
      # [1, 2, 3]

  The first example above translates to javascript:

      $('name').map(function() {
        return $(this).val()
      }).toArray()

  Available jQuery methods: 
      html text val 
      width height 
      innerWidth innerHeight outerWidth outerHeight 
      position offset scrollLeft scrollTop
      attr: val prop: val css: val data: val

  There is a shortcut to receive a list of classes from the selectors:

      classes = socket |> select(:classes, from: ".btn")

  ## :all
  In case when method is `:all`, executes all known methods on the given selector. Returns 
  Map `%{name|id => medthod_return_value}`. Uses `name` attribute as a key, or `id`, 
  when there is no `name`, or `__undefined_[number]`, when neither `id` or `name` are
  specified.

      socket |> select(:all, from: "span")
      %{"first_span" => %{"height" => 16, "html" => "First span with class qs_2", "innerHeight" => 20, ...

  Additionally, `id` and `name` attributes are included into a Map.
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
  def select(socket, method, from: selector) when method in @methods or method == :all do
    do_query(socket, selector, jquery_method(method), :select, @no_broadcast)
  end
  def select(socket, :classes, from: selector) do
    socket |> select(attr: "class", from: selector) |>  Enum.map(&String.split/1)
  end
  def select(_socket, method, from: selector) do
    wrong_query! selector, method 
  end

  @doc """
  Sets the DOM object property corresponding to the `method`. 

  In case when the method requires an argument (like `attr()`), it should be given as key/value pair: 
  method_name: "argument".
  
  Waits for the browser to finish the changes, returns socket so it can be stacked.

  Options:
  * on: selector - DOM selector, on which the changes are made
  * set: value - new value
  * attr: attribute - DOM attribute
  * prop: property - DOM property
  * class: class - class name to be replaced by another class
  * css: updates given css
  * data: updates data-* attribute

  Examples:
      socket |> update(:text, set: "saved...", on: "#save_button")
      socket |> update(attr: "style", set: "width: 100%", on: ".progress-bar")
      # the same effect:
      socket |> update(css: "width", set: "100%", on: ".progress-bar")

  Update can also switch the classes in DOM object (remove one and insert another):

      socket |> update(class: "btn-success", set: "btn-danger", on: "#save_button")

  You can also cycle between values - switch to the next value from the list 
  or to the first element, if the actual value is not on the list:

      socket |> update(:text, set: ["One", "Two", "Three"], on: "#thebutton")
      socket |> update(css: "font-size", set: ["8px", "10px", "12px"], on: "#btn")

  When cycling through the `class` attribute, system will update the class if it is one in the list.
  In the other case, it will add the first from the list.

      socket |> update(:class, set: ["btn-success", "btn-danger"], on: "#btn")

  Please notice that cycling is only possible on selectors which returns one node.

  Another possibility is to toggle (add if not exists, remove in the other case) the class:

      socket |> update(:class, toggle: "btn-success", on: "#btn")

  Available jQuery methods: see `Drab.Query.select/2`
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

  defp do_update(socket, broadcast, [{method, argument}, set: values, on: selector]) 
  when method in @methods_with_argument do
    value = next_value(socket, values, method, argument, selector)
    {:ok, do_query(socket, selector, jquery_method(method, argument, value), :update, broadcast)}
  end
  defp do_update(socket, broadcast, [class: from_class, set: to_class, on: selector]) do
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

  defp do_update(socket, broadcast, method, set: values, on: selector) when method in @methods do
    value = next_value(socket, values, method, selector)
    {:ok, do_query(socket, selector, jquery_method(method, value), :update, broadcast)}
  end
  defp do_update(socket, broadcast, :class, set: value, on: selector) when is_binary(value) do
    # shorthand for just a simple class update
    do_update(socket, broadcast, attr: "class", set: value, on: selector)
  end
  defp do_update(socket, broadcast, :class, toggle: value, on: selector) do
    {:ok, do_query(socket, selector, "toggleClass(\"#{value}\")", :update, broadcast)}    
  end
  defp do_update(socket, broadcast, :class, set: values, on: selector) when is_list(values) do
    # switch classes: updates the attr: "class" string with replacement of class, if it is on the list
    c = socket |> select(:classes, from: selector)
    one_element_selector_only!(c, selector)
    classes = c |> List.first()
    replaced = Enum.map(classes, fn c -> 
      if c in values do 
        next_in_list(values, c) 
      else 
        c 
      end
    end)
    classes_together = if replaced == classes do
      [List.first(values) | classes]
    else
      replaced
    end |> Enum.join(" ")
    do_update(socket, broadcast, attr: "class", set: classes_together, on: selector)
  end
  defp do_update(_socket, _broadcast, method, set: value, on: selector) do
    wrong_query! selector, method, value
  end

  # returns next value of the given list (cycle) or the first element of the list
  defp next_value(socket, values, method, selector) when is_list(values) do
    v = socket |> select(method, from: selector)
    one_element_selector_only!(v, selector)
    next_in_list(values, v |> List.first())
  end
  defp next_value(_socket, value, _method, _selector), do: value

  defp next_value(socket, values, method, argument, selector) when is_list(values) do
    v = socket |> select([{method, argument}, from: selector]) 
    one_element_selector_only!(v, selector)
    next_in_list(values, v |> List.first())
  end
  defp next_value(_socket, value, _method, _argument, _selector), do: value

  defp next_in_list(list, value) do
    pos = value && Enum.find_index(list, &(&1 == value))
    if pos do
      Enum.at(list, rem(pos+1, Enum.count(list)))
    else
      list |> List.first()
    end    
  end

  defp one_element_selector_only!(v, selector) do
    # TODO: maybe it would be better to allow multiple-element cycling?
    if Enum.count(v) != 1, do: raise "Cycle is possible only on one element selector, given: \"#{selector}\""
  end

  @doc """
  Adds new node (html) or class to the selected object.

  Waits for the browser to finish the changes and returns socket so it can be stacked.
  
  Options:
  * class: class - class name to be inserted
  * into: selector - class will be added to specified selectors; only applies with `:class` 
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

  # Build and run general jQuery query
  defp do_query(socket, selector, method_jqueried, type, push_or_broadcast_function) do
    push_or_broadcast_function.(socket, build_js(selector, method_jqueried, type))
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

  #TODO: move it to templates

  defp build_js(selector, "all()", :select) do
    #val: $(this).val(), html: $(this).html(), text: $(this).text()
    methods = Enum.map(@methods -- [:all], fn m -> "#{m}: $(this).#{m}()" end) |> Enum.join(", ")
    """
    var vals = {}
    var i = 0
    $('#{selector}').map(function() {
      var key = $(this).attr("name") || $(this).attr("id") || "__undefined_" + i++
      vals[key] = {#{methods}, id: $(this).attr('id'), name: $(this).attr('name')}
    })
    vals
    """
  end

  defp build_js(selector, method_javascripted, :select) do
    """
    $('#{selector}').map(function() {
      return $(this).#{method_javascripted}
    }).toArray()
    """
  end

  defp build_js(selector, method_javascripted, type) when type in ~w(update insert delete execute)a do
    # update events only when running .html() method
    update_events = if Regex.match?(@html_modifiers, method_javascripted) do
      "Drab.set_event_handlers('#{selector}')"
    else 
      ""
    end
    """
    $('#{selector}').#{method_javascripted}
    #{update_events}
    """
  end

  defp escape_value(value) when is_boolean(value),  do: "#{inspect(value)}"
  defp escape_value(value) when is_nil(value),      do: "\"\""
  defp escape_value(value),                         do: "#{Drab.Core.encode_js(value)}"

  defp wrong_query!(selector, method, arguments \\ nil) do
    raise ArgumentError, """
    Drab does not recognize your query:
      selector:  #{inspect(selector)}
      method:    #{inspect(method)}
      arguments: #{inspect(arguments)}
    """
  end

end
