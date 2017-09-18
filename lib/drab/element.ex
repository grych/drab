defmodule Drab.Element do
  @moduledoc """
  HTML element query and manipulation library.

  All functions are based on the CSS selectors. `query/3` runs `document.querySelector` and returns selected
  properties of found HTML elements.

  `set_prop/3` is a general function for update elements properties. There are also a bunch of helpers
  (`set_style/3` or `set_attr/3`), for updating a style of attributes of an element.
  """
  import Drab.Core
  require IEx
  use DrabModule

  @doc false
  def js_templates(),  do: ["drab.element.js"]

  @doc false
  def transform_payload(payload, _state) do
    payload
      |> Map.put_new("value", payload["val"])
      |> Map.put_new(:params, payload["form"])
  end

  @doc """
  Like `query/3`, but returns most popular properties. To be used for debugging / inspecting.

  Example:
      iex> query socket, "a"
      {:ok,
       %{"[drab-id='13114f0a-d65c-4486-b46e-86809aa00b7f']" => %{
             "attributes" => %{"drab-id" => "13114f0a-d65c-4486-b46e-86809aa00b7f",
             "href" => "http://tg.pl"}, "classList" => [], "className" => "",
           "dataset" => %{}, "drab_id" => "13114f0a-d65c-4486-b46e-86809aa00b7f",
           "id" => "", "innerHTML" => "tg.pl", "innerText" => "tg.pl", "name" => "",
           "style" => %{}, "tagName" => "A"}}}

  """
  def query(socket, selector) do
    query(socket, selector, [])
  end

  @doc """
  Queries for the selector in the browser and collects found element properties.

  `property_or_properties_list` specifies what properties will be returned. It may either be a string,
  an atom or a list of strings or atoms.

  Returns:

  * `{:ok, map}` - where the `map` contains queried elements.

    The keys are selectors which clearly identify the element: if the object has an `id` declared - a string
    of `"#id"`, otherwise Drab declares the `drab-id` attribute and the key became `"[drab-id='...']"`.

    Values of the map are maps of `%{property => property_value}`. Notice that for some properties (like
    `style` or `dataset`), the property_value is a map as well.

  * `{:error, message}` - the browser could not be queried


  Examples:
      iex> query socket, "button", :clientWidth
      {:ok, %{"#button1" => %{"clientWidth" => 66}}}

      iex(170)> query socket, "div", :id
      {:ok,
       %{"#begin" => %{"id" => "begin"}, "#drab_pid" => %{"id" => "drab_pid"},
         "[drab-id='472a5f90-c5cf-434b-bdf1-7ee236d67938']" => %{"id" => ""}}}

      iex> query socket, "button", ["dataset", "clientWidth"]
      {:ok,
       %{"#button1" => %{"clientWidth" => 66,
           "dataset" => %{"d1" => "[1,2,3]", "d1x" => "[1,2,3]", "d2" => "[1, 2]",
             "d3" => "d3"}}}}

  """
  def query(socket, selector, property_or_properties_list)
  def query(socket, selector, property) when is_binary(property) or is_atom(property) do
    query(socket, selector, [property])
  end

  def query(socket, selector, properties) when is_list(properties) do
    exec_js(socket, query_js(selector, properties))
  end

  @doc """
  Like `query!/3`, but returns most popular properties. To be used for debugging / inspecting.
  """
  def query!(socket, selector) do
    query!(socket, selector, [])
  end


  @doc """
  Like `query/3`, but raises instead of returning `{:error, reason}`.
  """
  def query!(socket, selector, property_or_properties_list)
  def query!(socket, selector, property) when is_binary(property) or is_atom(property) do
    query!(socket, selector, [property])
  end

  def query!(socket, selector, properties) when is_list(properties) do
    exec_js!(socket, query_js(selector, properties))
  end

  defp query_js(selector, properties) do
    "Drab.query(#{encode_js(selector)}, #{encode_js(properties)})"
  end

  @doc """
  Like `query_one/3`, but returns most popular properties. To be used for debugging / inspecting.
  """
  def query_one(socket, selector) do
    query_one(socket, selector, [])
  end

  @doc """
  Queries the browser for elements with selector. Expects at most one element to be found.

  Similar to `query/3`, but always returns a map of properties of one element (or `{:ok, nil}` if not found).
  Returns `{:too_many, message}` if found more than one element.

  Examples:
      iex> query_one socket, "button", :innerText
      {:ok, %{"innerText" => "Button"}}

      iex> query_one socket, "button", ["innerHTML", "dataset"]
      {:ok,
       %{"dataset" => %{"d1" => "1", "d2" => "[1, 2]", "d3" => "d3"},
         "innerHTML" => "\\n  Button\\n"}}

  """
  def query_one(socket, selector, property_or_properties_list) do
    case query(socket, selector, property_or_properties_list) do
      {:ok, map} ->
        case Map.keys(map) do
          []    -> {:ok, nil}
          [key] -> {:ok, map[key]}
          _     -> {:too_many, query_one_error_message(map, selector)}
        end
      other ->
        other
    end
  end

  @doc """
  Like `query_one!/3`, but returns most popular properties. To be used for debugging / inspecting.
  """
  def query_one!(socket, selector) do
    query_one!(socket, selector, [])
  end

  @doc """
  Exception raising version of `query_one/3`.
  """
  def query_one!(socket, selector, property_or_properties_list) do
    map = query!(socket, selector, property_or_properties_list)
    case Map.keys(map) do
      []    -> nil
      [key] -> map[key]
      _     -> raise query_one_error_message(map, selector)
    end
  end

  defp query_one_error_message(map, selector) do
    "#{Enum.count(map)} elements found with selector \"#{selector}\", expected 1 or 0"
  end

  @doc """
  Finds all html elements using `selector` and sets their properties.

  Takes a map or keyword list of properties to be set, where the key is a property name and the value
  is the new value to be set. If the property is a Javascript object (like `style` or `attributes`), it expects
  a map.

  Returns tuple `{:ok, number}` with number of updated elements or `{:error, description}`.

  Examples:

      iex> set_prop socket, "a", %{"attributes" => %{"class" => "btn btn-warning"}}
      {:ok, 1}

      iex> set_prop socket, "button", style: %{"backgroundColor" => "red", "width" => "200px"}
      {:ok, 1}

      iex> set_prop socket, "div", innerHTML: "updated"
      {:ok, 3}

  You may store any JS encodable value in the property:

      iex> set_prop socket, "#button1", custom: %{example: [1, 2, 3]}
      {:ok, 1}
      iex> query_one socket, "#button1", :custom
      {:ok, %{"custom" => %{"example" => [1, 2, 3]}}}
  """
  def set_prop(socket, selector, properties) when is_map(properties) or is_list(properties) do
    exec_js(socket, set_js(selector, Map.new(properties)))
  end

  @doc """
  Bang version of `set_prop/3`, raises exception on error.

  Returns number of updated element.
  """
  def set_prop!(socket, selector, properties) when is_map(properties) or is_list(properties) do
    exec_js!(socket, set_js(selector, Map.new(properties)))
  end

  defp set_js(selector, properties) do
    "Drab.set_prop(#{encode_js(selector)}, #{encode_js(properties)})"
  end

  @doc """
  Broadcasting version of `set_prop/3`.

  It does exactly the same as `set_prop/3`, but instead of pushing the message to the current browser,
  it broadcasts it to all connected users.

  Always returns `{:ok, :broadcasted}`.

  See `Drab.Core.broadcast_js/2` for broadcasting options.
  """
  def broadcast_prop(subject, selector, properties) when is_map(properties) or is_list(properties) do
    broadcast_js(subject, set_js(selector, Map.new(properties)))
  end

  @doc """
  Helper for setting the `style` property of found elements. A shorthand for:

      set_prop(socket, selector, %{"style" => properties}})

  Examples:

      iex> set_style socket, "button", %{"backgroundColor" => "red"}
      {:ok, 1}

      iex> set_style socket, "button", height: "100px", width: "200px"
      {:ok, 1}

  """
  def set_style(socket, selector, properties) when is_list(properties) or is_map(properties) do
    set_prop socket, selector, %{"style" => Map.new(properties)}
  end

  @doc """
  Bang version of `set_style/3`. Raises exception on error.
  """
  def set_style!(socket, selector, properties) when is_list(properties) or is_map(properties) do
    set_prop! socket, selector, %{"style" => Map.new(properties)}
  end

  @doc """
  Helper for setting the attributes of found elements. A shorthand for:

      set_prop(socket, selector, %{"attributes" => attributes})

  Examples:

      iex> set_attr socket, "a", href: "https://tg.pl/drab"
      {:ok, 1}
  """
  def set_attr(socket, selector, attributes) when is_list(attributes) or is_map(attributes) do
    set_prop socket, selector, %{"attributes" => Map.new(attributes)}
  end

  @doc """
  Bang version of `set_attr/3`. Raises exception on error.
  """
  def set_attr!(socket, selector, attributes) when is_list(attributes) or is_map(attributes) do
    set_prop! socket, selector, %{"attributes" => Map.new(attributes)}
  end

  @doc """
  Helper for setting the dataset of elements. A shorthand for:

      set_prop(socket, selector, %{"dataset" => dataset})

  Examples:

      iex> set_data socket, "button", foo: "bar"
      {:ok, 1}
  """
  def set_data(socket, selector, dataset) when is_list(dataset) or is_map(dataset) do
    set_prop socket, selector, %{"dataset" => Map.new(dataset)}
  end

  @doc """
  Bang version of `set_data/3`. Raises exception on error.
  """
  def set_data!(socket, selector, dataset) when is_list(dataset) or is_map(dataset) do
    set_prop! socket, selector, %{"dataset" => Map.new(dataset)}
  end

  @doc """
  Parses the specified text as HTML and inserts the resulting nodes into the DOM tree at a specified position.

  Position is the position relative to the element found by the selector, and must be one of the following strings
  or atoms:

  * `:beforebegin` - before the found element
  * `:afterbegin` - inside the element, before its first child
  * `:beforeend` - inside the element, after its last child
  * `:afterend` - after the element itself

  Visit https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentHTML for more information.

  Returns tuple `{:ok, number}` with number of updated elements or `{:error, description}`.

  Examples:

      ex> insert_html(socket, "div", :beforebegin, "<b>MORE</b>")
      {:ok, 3}
  """
  def insert_html(socket, selector, position, html) do
    exec_js(socket, insert_js(selector, position, html))
  end

  @doc """
  Exception-throwing version of `insert_html/4`
  """
  def insert_html!(socket, selector, position, html) do
    exec_js!(socket, insert_js(selector, position, html))
  end

  @doc """
  Broadcasting version of `insert_html/4`.

  It does exactly the same as `insert_html/4`, but instead of pushing the message to the current browser,
  it broadcasts it to all connected users.

  Always returns `{:ok, :broadcasted}`.

  See `Drab.Core.broadcast_js/2` for broadcasting options.
  """
  def broadcast_insert(subject, selector, position, html) do
    broadcast_js(subject, insert_js(selector, position, html))
  end

  defp insert_js(selector, position, html) do
    "Drab.insert_html(#{encode_js(selector)}, #{encode_js(position)}, #{encode_js(html)})"
  end

end
