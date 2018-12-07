defmodule Drab.Live do
  @moduledoc """
  Drab Module to provide a live access and update of assigns of the template, which is currently
  rendered and displayed in the browser.

  The idea is to reuse your Phoenix templates and let them live, to make a possibility to update
  assigns on the living page, from the Elixir, without re-rendering the whole html. But because
  Drab tries to update the smallest amount of the html, there are some limitations, for example,
  it when updating the nested block it does not know the local variables used before. Please check
  out `Drab.Live.EExEngine` for more detailed description.

  Use `peek/2` to get the assign value, and `poke/2` to modify it directly in the DOM tree.

  Drab.Live uses the modified EEx Engine (`Drab.Live.EExEngine`) to compile the template and
  indicate where assigns were rendered. To enable it, rename the template you want to go live
  from extension `.eex` to `.drab`. Then, add Drab Engine to the template engines in `config.exs`:

      config :phoenix, :template_engines,
        drab: Drab.Live.Engine

  ## Performance
  `Drab.Live` re-renders the page at the backend and pushes only the changed parts to the fronted.
  Thus it is not advised to use it in the big, slow rendering pages. In this case it is better
  to split the page to the partials and `poke` in the partial only, or use light update with
  `Drab.Element` or `Drab.Query`.

  Also, it is not advised to use `Drab.Live` with big assigns - they must be transferred from the
  client when connected.

  ## Avoiding using Drab
  If there is no need to use Drab with some expression, you may mark it with `nodrab/1` function.
  Such expressions will be treated as a "normal" Phoenix expressions and will not be updatable
  by `poke/2`.

      <p>Chapter <%= nodrab(@chapter_no) %>.</p>

  Since Elixir 1.6, you may use the special marker "/", which does exactly the same as `nodrab`:

      <p>Chapter <%/ @chapter_no %>.</p>

  ### The `@conn` case
  The `@conn` assign is often used in Phoenix templates. Drab considers it read-only, you can not
  update it with `poke/2`. And, because it is often quite hudge, may significantly increase
  the number of data sent to and back from the browser. This is why by default Drab trims `@conn`,
  leaving only the essential fields, by default `:private => :phoenix_endpoint`.

  This behaviour is configuable with `:live_conn_pass_through`. For example, if you want to preseve
  the specific assigns in the conn struct, mark them as true in the config:

      config :drab, MyAppWeb.Endpoint,
        live_conn_pass_through: %{
          assigns: %{
            users: true
          },
          private: %{
            phoenix_endpoint: true
          }
        }

  ## Shared Commanders
  When the event is triggered inside the Shared Commander, defined with `drab-commander` attribute,
  all the updates will be done only withing this region. For example:

      <div drab-commander="DrabTestApp.Shared1Commander">
        <div><%= @assign1 %></div>
        <button drab-click="button_clicked">Shared 1</button>
      </div>
      <div drab-commander="DrabTestApp.Shared1Commander">
        <div><%= @assign1 %></div>
        <button drab-click="button_clicked">Shared 2</button>
      </div>

      defhandler button_clicked(socket, sender) do
        poke socket, assign1: "changed"
      end

  This will update only the div with `@assign1` in the same `<div drab-commander>` as the button.

  Please notice it works also for `peek` - it will return the proper value, depends where the event
  is triggered.

  ## Caching
  Browser communication is the time consuming operation and depends on the network latency. Because
  of this, Drab caches the values of assigns in the current event handler process, so they don't
  have to be re-read from the browser on every `poke` or `peek` operation. The cache is per
  process and lasts only during the lifetime of the event handler.

  This, event handler process keeps all the assigns value until it ends. Please notice that
  the other process may update the assigns on the page in the same time, by using broadcasting
  functions, when your event handler is still running. If you want to re-read the assigns cache,
  run `clean_cache/0`.

  ## Partials
  Function `poke/2` and `peek/2` works on the default template - the one rendered with
  the Controller. In case there are some child templates, rendered inside the main one, you need
  to specify the template name as a second argument of `poke/3` and `peek/3` functions.

  In case the template is not under the current (main) view, use `poke/4` and `peek/4` to specify
  the external view name.

  Assigns are archored within their partials. Manipulation of the assign outside the template it
  lives will raise `ArgumentError`. *Partials are not hierachical*, eg. modifying the assign
  in the main partial will not update assigns in the child partials, even if they exist there.

  ### Rendering partial templates in a runtime
  There is a possibility add the partial to the DOM tree in a runtime, using `render_to_string/2`
  helper:

      poke socket, live_partial1: render_to_string("partial1.html", color: "#aaaabb")

  But remember that assigns are assigned to the partials, so after adding it to the page,
  manipulation must be done within the added partial:

      poke socket, "partial1.html", color: "red"

  ### Limitions
  Because Drab must interpret the template, inject it's ID etc, it assumes that the template HTML
  is valid. There are also some limits for defining properties. See `Drab.Live.EExEngine` for
  a full description.

  ## Update Behaviours
  There are different behaviours of `Drab.Live`, depends on where the expression with the updated
  assign lives. For example, if the expression defines tag attribute, like
  `<span class="<%= @class %>">`, we don't want to re-render the whole tag, as it might override
  changes you made with other Drab module, or even with Javascript. Because of this, Drab finds
  the tag and updates only the required attributes.

  ### Plain Text
  If the expression in the template is given in any tag body, Drab will try to find the sourrounding
  tag and mark it with the attribute called `drab-ampere`. The attribute value is a hash of the
  previous buffer and the expression itself.

  Consider the template, with assign `@chapter_no` with initial value of `1` (given in render
  function in the controller, as usual):

      <p>Chapter <%= @chapter_no %>.</p>

  which renders to:

      <p drab-ampere="someid">Chapter 1.</p>

  This `drab-ampere` attribute is injected automatically by `Drab.Live.EExEngine`. Updating the
  `@chapter_no` assign in the Drab Commander, by using `poke/2`:

      chapter = peek(socket, :chapter_no)     # get the current value of `@chapter_no`
      poke(socket, chapter_no: chapter + 1)   # push the new value to the browser

  will change the `innerHTML` of the `<p drab-ampere="someid">` to "Chapter 2." by executing
  the following JS on the browser:

      document.querySelector('[drab-ampere=someid]').innerHTML = "Chapter 2."

  This is possible because during the compile phase, Drab stores the `drab-ampere` and
  the corresponding pattern in the cache DETS file (located in `priv/`).

  ### Injecting `<span>`
  In case, when Drab can't find the parent tag, it injects `<span>` in the generated html. For
  example, template like:

      Chapter <%= @chapter_no %>.

  renders to:

      Chapter <span drab-ampere="someid">1</span>.

  ### Attributes
  When the expression is defining the attribute of the tag, the behaviour if different. Let's
  assume there is a template with following html, rendered in the Controller with value of
  `@button` set to string `"btn-danger"`.

      <button class="btn <%= @button %>">

  It renders to:

      <button drab-ampere="someid" class="btn btn-danger">

  Again, you can see injected `drab-ampere` attribute. This allows Drab to indicate where
  to update the attribute. Pushing the changes to the browser with:

      poke socket, button: "btn btn-info"

  will result with updated `class` attribute on the given tag. It is acomplished by running
  `node.setAttribute("class", "btn btn-info")` on the browser.

  Notice that the pattern where your expression lives is preserved: you may update only the partials
  of the attribute value string.

  #### Updating `value` attribute for `<input>` and `<textarea>`
  There is a special case for `<input>` and `<textarea>`: when poking attribute of `value`, Drab
  updates the corresponding `value` property as well.

  ### Properties
  Nowadays we deal more with node properties than attributes. This is why `Drab.Live` introduces
  the special syntax. When using the `@` sign at the beginning of the attribute name, it will
  be treated as a property.

      <button @hidden=<%= @hidden %>>

  Updating `@hidden` in the Drab Commander with `poke/2` will change the value of the `hidden`
  property (without dollar sign!), by sending the update javascript: `node['hidden'] = false`.

  You may also dig deeper into the Node properties, using dot - like in JavaScript - to bind
  the expression with the specific property. The good example is to set up `.style`:

      <button @style.backgroundColor=<%= @color %>>

  Additionally, Drab sets up all the properties defined that way when the page loads. Thanks to
  this, you don't have to worry about the initial value.

  Notice that `@property=<%= expression %>` **is the only available syntax**, you can not use
  string pattern or give more than one expression. Property must be stronly bind to the expression.
  You also can't use quotes or apostrophes sourrounding the expressio. This is because it does
  not have to be a string, but any JSON encodable value.

  The expression binded with the property **must be encodable to JSON**, so, for example, tuples
  are not allowed here. Please refer to `Jason` docs for more information about encoding JS.

  ### Scripts
  When the assign we want to change is inside the `<script></script>` tag, Drab will re-evaluate
  the whole script after assigment change. Let's say you don't want to use
  `@property=<%=expression%>` syntax to define the object property. You may want to render
  the javascript:

      <script>
        document.querySelectorAll("button").hidden = <%= @buttons_state %>
      </script>

  If you render the template in the Controller with `@button_state` set to `false`, the initial html
  will look like:

      <script drab-ampere="someid">
        document.querySelectorAll("button").hidden = false
      </script>

  Again, Drab injects some ID to know where to find its victim. After you `poke/2` the new value
  of `@button_state`, Drab will re-render the whole script with a new value and will send
  a request to re-evaluate the script. Browser will run something like:
  `eval("document.querySelectorAll(\"button\").hidden = true")`.

  Please notice this behaviour is disabled by default for safety. To enable it, use the following
  in your `config.exs`:

      config :drab, enable_live_scripts: true

  ## Broadcasting
  There is a function `broadcast_poke` to broadcast living assigns to more than one browser.
  * It should be used with caution *.

  When you are broadcasting, you must be aware that the template is re-rendered only once for the
  client which triggered the action, not for all the browsers.

  For broadcasting using a `subject` instead of `socket` (like `same_action/1`), Drab is unable
  to automatically retrieve view and template name, as well as existing assigns values. This,
  the only acceptable version is `broadcast_poke/4` with `:using_assigns` option.

      iex> broadcast_poke same_action(MyApp.PageController, :mini), MyApp.PageView, "index.html",
           text: "changed text", using_assigns: [color: "red"]
  """

  @type result :: Phoenix.Socket.t() | Drab.Core.result() | integer | no_return

  import Drab.Core
  require IEx
  alias Drab.Live.{Partial, Ampere}
  use DrabModule

  @impl true
  def js_templates(), do: ["drab.live.js"]

  @impl true
  def transform_socket(socket, payload, _state) do
    socket =
      Phoenix.Socket.assign(
        socket,
        :__sender_drab_commander_id,
        payload["drab_commander_id"] || "document"
      )

    socket =
      Phoenix.Socket.assign(
        socket,
        :__sender_drab_commander_amperes,
        payload["drab_commander_amperes"] || []
      )

    socket =
      Phoenix.Socket.assign(
        socket,
        :__drab_index,
        payload["drab_index"] || nil
      )

    Phoenix.Socket.assign(
      socket,
      :__csrf_token,
      payload["csrf_token"] || nil
    )
  end

  @doc """
  Returns the current value of the assign from the current (main) partial.

      iex> peek(socket, :count)
      {ok, 42}
      iex> peek(socket, :nonexistent)
      ** (ArgumentError) Assign @nonexistent not found in Drab EEx template

  Notice that this is a value of the assign, and not the value of any node property or attribute.
  Assign gets its value only while rendering the page or via `poke`. After changing the value
  of node attribute or property on the client side, the assign value will remain the same.
  """
  @spec peek(Phoenix.Socket.t(), atom) :: result | no_return
  def peek(socket, assign), do: peek(socket, nil, nil, assign)

  @doc """
  Like `peek/2`, but takes partial name and returns assign from that specified partial.

  Partial is taken from the current view.

      iex> peek(socket, "users.html", :count)
      {:ok, 42}
  """
  @spec peek(Phoenix.Socket.t(), String.t(), atom) :: result | no_return
  def peek(socket, partial, assign), do: peek(socket, nil, partial, assign)

  @doc """
  Like `peek/2`, but takes a view and a partial name and returns assign from that specified
  view/partial.

      iex> peek(socket, MyApp.UserView, "users.html", :count)
      {:ok, 42}
  """
  @spec peek(Phoenix.Socket.t(), atom | nil, String.t() | nil, atom | String.t()) ::
          result | no_return
  def peek(socket, view, partial, assign) when is_atom(assign) do
    case assigns_and_nodrab(socket) do
      {:ok, assigns_data} ->
        do_peek(socket, view, partial, assign, assigns_data)

      error ->
        error
    end
  end

  def peek(socket, view, partial, assign) when is_binary(assign) do
    peek(socket, view, partial, String.to_existing_atom(assign))
  end

  defp do_peek(socket, view, partial, assign, assigns_data) do
    view = view || Drab.get_view(socket)
    hash = if partial, do: Partial.hash_for_view_and_name(view, partial), else: index(socket)

    all_assigns =
      Map.merge(
        assigns_for_partial(socket, hash, partial, :assigns, assigns_data),
        assigns_for_partial(socket, hash, partial, :nodrab, assigns_data)
      )

    case all_assigns |> Map.fetch(assign) do
      {:ok, val} ->
        {:ok, val}

      :error ->
        raise_assign_not_found(
          assign,
          Map.keys(all_assigns)
        )
    end
  end

  @doc """
  Exception raising version of `peek/2`.

  Returns the current value of the assign from the current (main) partial.

      iex> peek!(socket, :count)
      42
      iex> peek!(socket, :nonexistent)
      ** (ArgumentError) Assign @nonexistent not found in Drab EEx template
  """
  @spec peek!(Phoenix.Socket.t(), atom) :: term | no_return
  def peek!(socket, assign), do: peek!(socket, nil, nil, assign)

  @doc """
  Exception raising version of `peek/3`.

      iex> peek!(socket, "users.html", :count)
      42
  """
  @spec peek!(Phoenix.Socket.t(), String.t(), atom) :: term | no_return
  def peek!(socket, partial, assign), do: peek!(socket, nil, partial, assign)

  @doc """
  Exception raising version of `peek/4`.

      iex> peek(socket, MyApp.UserView, "users.html", :count)
      42
  """
  @spec peek!(Phoenix.Socket.t(), atom | nil, String.t() | nil, atom | String.t()) ::
          term | no_return
  def peek!(socket, view, partial, assign) when is_atom(assign) do
    case assigns_and_nodrab(socket) do
      {:ok, assigns_data} ->
        Drab.JSExecutionError.result_or_raise(
          do_peek(socket, view, partial, assign, assigns_data)
        )

      {:error, description} ->
        raise Drab.JSExecutionError, message: to_string(description)
    end
  end

  def peek!(socket, view, partial, assign) when is_binary(assign) do
    peek(socket, view, partial, String.to_existing_atom(assign))
  end

  @doc """
  Updates the current page in the browser with the new assign value.

  Works inside the main partial - the one rendered in the controller - only. Does not touch children
  partials, even if they contain the given assign.

  Raises `ArgumentError` when assign is not found within the partial. Please notice that only
  assigns rendered with `<%= %>` mark are *pokeable*; assigns rendered with `<% %>` or `<%/ %>`
  only can't be updated by `poke`.

  Returns `{:error, description}` or `{:ok, N}`, where N is the number of updates on the page. It
  combines all the operations, so updating properties, attributes, text, etc.

      iex> poke(socket, count: 42)
      {:ok, 3}

  Passed values could be any JSON serializable term, or Phoenix safe html. It is recommended to
  use safe html, when dealing with values which are coming from the outside world, like user inputs.

      import Phoenix.HTML # for sigil_E
      username = sender.params["username"]
      html = ~E"User: <%= username %>"
      poke socket, username: html
  """
  @spec poke(Phoenix.Socket.t(), Keyword.t()) :: result
  def poke(socket, assigns) do
    # do_poke(socket, nil, nil, assigns, &Drab.Core.exec_js/2)
    poke(socket, nil, nil, assigns)
  end

  @doc """
  Like `poke/2`, but limited only to the given partial name.

      iex> poke(socket, "user.html", name: "Bożywój")
      {:ok, 3}
  """
  @spec poke(Phoenix.Socket.t(), String.t() | nil, Keyword.t()) :: result
  def poke(socket, partial, assigns) do
    # do_poke(socket, nil, partial, assigns, &Drab.Core.exec_js/2)
    poke(socket, nil, partial, assigns)
  end

  @doc """
  Like `poke/3`, but searches for the partial within the given view.

      iex> poke(socket, MyApp.UserView, "user.html", name: "Bożywój")
      {:ok, 3}
  """
  @spec poke(Phoenix.Socket.t(), atom | nil, String.t() | nil, Keyword.t()) :: result
  def poke(socket, view, partial, assigns) do
    do_poke(socket, view, partial, assigns, &Drab.Core.exec_js/2)
  end

  @doc """
  Exception raising version of `poke/2`.

  Returns integer, which is the number of updates on the page. It combines all the operations,
  so updating properties, attributes, text, etc.

      iex> poke!(socket, count: 42)
      3
  """
  @spec poke!(Phoenix.Socket.t(), Keyword.t()) :: integer | no_return
  def poke!(socket, assigns) do
    poke!(socket, nil, nil, assigns)
  end

  @doc """
  Exception raising version of `poke/3`.

  Returns integer, which is the number of updates on the page. It combines all the operations,
  so updating properties, attributes, text, etc.

      iex> poke!(socket, "user.html", name: "Bożywój")
      0
  """
  @spec poke!(Phoenix.Socket.t(), String.t() | nil, Keyword.t()) :: integer | no_return
  def poke!(socket, partial, assigns) do
    poke!(socket, nil, partial, assigns)
  end

  @doc """
  Exception raising version of `poke/4`.

  Returns integer, which is the number of updates on the page. It combines all the operations,
  so updating properties, attributes, text, etc.

      iex> poke!(socket, MyApp.UserView, "user.html", name: "Bożywój")
      0
  """
  @spec poke!(Phoenix.Socket.t(), atom | nil, String.t() | nil, Keyword.t()) ::
          integer | no_return
  def poke!(socket, view, partial, assigns) do
    socket
    |> do_poke(view, partial, assigns, &Drab.Core.exec_js!/2)
  end

  @doc """
  Broadcasting version of `poke/2`.

  Please notice that broadcasting living assigns makes sense only for the pages, which was rendered
  with the same templates.

  Broadcasting the poke is a non-trivial operation, and you must be aware that the local
  assign cache of the handler process is not updated on any of the browsers. This mean that
  `peek/2` may return obsolete values.

  Also, be aware that the page is re-rendered only once, within the environment from the browser
  which triggered the action, and the result of this is sent to all the clients. So it makes sence
  only when you have the same environment eveywhere (no `client_id` in assigns, etc). In the other
  case, use other broadcasting functions from the other modules, like `Drab.Element`.

  Returns `{:ok, :broadcasted}`.

      iex> broadcast_poke(socket, count: 42)
      %Phoenix.Socket{ ...
  """
  @spec broadcast_poke(Drab.Core.subject(), Keyword.t()) :: result | no_return
  def broadcast_poke(%Phoenix.Socket{} = socket, assigns) do
    broadcast_poke(socket, nil, nil, assigns)
  end

  def broadcast_poke(_, _) do
    raise_broadcast_poke_with_subject()
  end

  @doc """
  Like `broadcast_poke/2`, but limited only to the given partial name.

      iex> broadcast_poke(socket, "user.html", name: "Bożywój")
      {:ok, :broadcasted}
  """
  @spec broadcast_poke(Drab.Core.subject(), String.t() | nil, Keyword.t()) :: result | no_return
  def broadcast_poke(%Phoenix.Socket{} = socket, partial, assigns) do
    broadcast_poke(socket, nil, partial, assigns)
  end

  def broadcast_poke(_, _, _) do
    raise_broadcast_poke_with_subject()
  end

  @doc """
  Like `broadcast_poke/3`, but searches for the partial within the given view.

      iex> broadcast_poke(socket, MyApp.UserView, "user.html", name: "Bożywój")
      {:ok, :broadcasted}

  This function allow to use `subject` instead of `socket` to broadcast living assigns without
  having a `socket`. In this case, you need to provide **all other assigns** to the function,
  with `:using_assigns` option.

      iex> broadcast_poke same_action(MyApp.PageController, :mini), MyApp.PageView, "index.html",
           text: "changed text", using_assigns: [color: "red"]
      {:ok, :broadcasted}

  Hint: if you have functions using `@conn` assign, you may fake it with
  `%Plug.Conn{private: %{:phoenix_endpoint => MyAppWeb.Endpoint}}`
  """
  @spec broadcast_poke(Drab.Core.subject(), atom | nil, String.t() | nil, Keyword.t()) ::
          result | no_return
  def broadcast_poke(%Phoenix.Socket{} = socket, view, partial, assigns) do
    do_poke(socket, view, partial, assigns, &Drab.Core.broadcast_js/2)
  end

  def broadcast_poke(subject, view, partial, assigns) do
    {_, options} = extract_options(assigns)

    unless options[:using_assigns] do
      raise_broadcast_poke_with_subject()
    end

    do_poke(subject, view, partial, assigns, &Drab.Core.broadcast_js/2)
  end

  @spec do_poke(Drab.Core.subject(), atom | nil, String.t() | nil, Keyword.t(), function) ::
          integer | result | no_return
  defp do_poke(socket, view, partial_name, assigns, function) do
    raise_if_read_only(assigns)
    {assigns, options} = extract_options(assigns)
    predefined_assigns = options[:using_assigns]

    assigns = desafe_values(assigns)
    view = view || Drab.get_view(socket)

    partial =
      if partial_name, do: Partial.hash_for_view_and_name(view, partial_name), else: index(socket)

    case assigns_and_nodrab(socket) do
      {:ok, assigns_data} ->
        process_poke(
          socket,
          view,
          partial,
          assigns,
          if predefined_assigns do
            predefined_assigns |> Enum.into(%{}) |> Map.merge(assigns)
          else
            assigns_for_partial(socket, partial, partial_name, :assigns, assigns_data)
          end,
          if predefined_assigns do
            %{}
          else
            assigns_for_partial(socket, partial, partial_name, :nodrab, assigns_data)
          end,
          assigns_data,
          function,
          options
        )

      {:error, description} = error ->
        if function == (&Drab.Core.exec_js!/2) do
          raise Drab.JSExecutionError, message: to_string(description)
        else
          error
        end
    end
  end

  defp process_poke(
         subject,
         view,
         partial,
         assigns_to_update,
         current_assigns,
         nodrab_assigns,
         assigns_data,
         function,
         _options
       ) do
    all_assigns = all_assigns(assigns_to_update, current_assigns, nodrab_assigns)
    html = rerender_template(subject, view, partial, all_assigns)

    update_javascripts =
      update_javascripts(subject, html, partial, assigns_to_update, current_assigns)

    assign_updates = assign_updates_js(assigns_to_update, partial, drab_commander_id(subject))
    all_javascripts = (assign_updates ++ update_javascripts) |> Enum.uniq() |> Enum.join(";")
    all_javascripts = "var n=0;" <> all_javascripts <> ";n"
    # IO.inspect update_javascripts
    # IO.inspect(all_javascripts)
    # IO.inspect(function)

    case function.(subject, all_javascripts) do
      {:ok, :broadcasted} ->
        {:ok, :broadcasted}

      {:ok, _} = ret ->
        update_assigns_cache(assigns_to_update, partial, drab_commander_id(subject), assigns_data)
        ret

      ret ->
        ret
    end
  end

  @doc false
  def drab_options_list, do: [:using_assigns, :drab_timeout]

  defp extract_options(assigns) do
    Enum.split_with(assigns, fn {x, _} -> x not in drab_options_list() end)
  end

  @doc false
  def reserved_assigns?(assigns) do
    intersection(assigns, drab_options_list()) != []
  end

  defp all_assigns(assigns, current_assigns, nodrab_assigns) do
    updated_assigns = Map.merge(current_assigns, assigns)
    all_assigns = Map.merge(nodrab_assigns, updated_assigns)
    Enum.into(all_assigns, [])
  end

  defp rerender_template(socket, view, partial, all_assigns) do
    template = Partial.template_filename(view, partial)
    html = Phoenix.View.render_to_string(view, template, all_assigns)
    update_csrf_token(html, csrf_token(socket))
  end

  defp assigns_to_update_keys(assigns_to_update, current_assigns_keys) do
    assigns_to_update_keys = Map.keys(assigns_to_update)

    for as <- assigns_to_update_keys do
      unless Enum.find(current_assigns_keys, fn key -> key == as end) do
        raise_assign_not_found(as, current_assigns_keys)
      end
    end

    assigns_to_update_keys
  end

  defp amperes_to_update(
         %Phoenix.Socket{} = socket,
         partial,
         assigns_to_update,
         current_assigns_keys
       ) do
    assigns_to_update_keys = assigns_to_update_keys(assigns_to_update, current_assigns_keys)
    amperes_to_update = Partial.amperes_for_assigns(partial, assigns_to_update_keys)

    # update only those which are in shared commander
    case socket.assigns[:__sender_drab_commander_amperes] do
      [] ->
        amperes_to_update

      sender_drab_commader_amperes ->
        intersection(amperes_to_update, sender_drab_commader_amperes)
    end
  end

  defp amperes_to_update(_subject, partial, assigns_to_update, current_assigns_keys) do
    assigns_to_update_keys = assigns_to_update_keys(assigns_to_update, current_assigns_keys)
    Partial.amperes_for_assigns(partial, assigns_to_update_keys)
  end

  defp update_javascripts(socket, html, partial, assigns_to_update, current_assigns) do
    current_assigns_keys = Map.keys(current_assigns)

    amperes_to_update =
      amperes_to_update(socket, partial, assigns_to_update, current_assigns_keys)

    js =
      for ampere <- amperes_to_update,
          %Ampere{gender: gender, tag: tag, attribute: prop_or_attr} <-
            Partial.partial(partial).amperes[ampere] do
        case gender do
          :html -> update_html_js(html, ampere, tag)
          :attr -> update_attr_js(html, ampere, prop_or_attr)
          :prop -> update_prop_js(html, ampere, prop_or_attr)
        end
      end

    Enum.sort_by(js, &has_amperes/1)
  end

  defp update_html_js(html, ampere, tag) do
    case Floki.find(html, "[drab-ampere='#{ampere}']") do
      [{_, _, value}] ->
        new_value = Floki.raw_html(value, encode: false)

        case {tag, Drab.Config.get(:enable_live_scripts)} do
          {"script", false} ->
            nil

          {_, _} ->
            "n+=Drab.update_tag(#{encode_js(tag)},#{encode_js(ampere)},#{encode_js(new_value)})"
        end

      _ ->
        nil
    end
  end

  defp update_attr_js(html, ampere, attr) do
    case Floki.attribute(html, "[drab-ampere='#{ampere}']", attr) do
      [new_value] ->
        "n+=Drab.update_attribute(#{encode_js(ampere)},#{encode_js(attr)},#{encode_js(new_value)})"

      _ ->
        nil
    end
  end

  defp update_prop_js(html, ampere, prop) do
    case Floki.attribute(html, "[drab-ampere='#{ampere}']", "@#{String.downcase(prop)}") do
      [new_value] ->
        "n+=Drab.update_property(#{encode_js(ampere)},#{encode_js(prop)},#{encode_js(new_value)})"

      _ ->
        nil
    end
  end

  @spec has_amperes(String.t() | nil) :: integer
  defp has_amperes(nil), do: 0

  defp has_amperes(string) do
    length(String.split(string, "drab-ampere")) - 1
  end

  @spec intersection(list, list) :: list
  defp intersection(list1, list2) do
    MapSet.to_list(MapSet.intersection(MapSet.new(list1), MapSet.new(list2)))
  end

  @spec update_csrf_token(String.t(), String.t() | nil) :: Floki.html_tree() | String.t()
  defp update_csrf_token(html, nil), do: html

  defp update_csrf_token(html, csrf) do
    html
    |> Floki.parse()
    |> Floki.attr("input[name='_csrf_token']", "value", fn _ -> csrf end)
    |> Floki.attr("button[data-csrf]", "data-csrf", fn _ -> csrf end)
    |> Floki.attr("a[data-csrf]", "data-csrf", fn _ -> csrf end)
  end

  @doc """
  Returns a list of the assigns for the main partial.

  Examples:

      iex> Drab.Live.assigns(socket)
      [:welcome_text]
  """
  @spec assigns(Phoenix.Socket.t()) :: list
  def assigns(socket) do
    assigns(socket, nil, nil)
  end

  @doc """
  Like `assigns/1` but will return the assigns for a given `partial` instead of the main partial.

  Examples:

      iex> assigns(socket, "user.html")
      [:name, :age, :email]
  """
  @spec assigns(Phoenix.Socket.t(), String.t() | nil) :: list
  def assigns(socket, partial) do
    assigns(socket, nil, partial)
  end

  @doc """
  Like `assigns/2`, but returns the assigns for a given combination of a `view` and a `partial`.

      iex> assigns(socket, MyApp.UserView, "user.html")
      [:name, :age, :email]
  """
  @spec assigns(Phoenix.Socket.t(), atom | nil, String.t() | nil) :: list
  def assigns(socket, view, partial) do
    view = view || Drab.get_view(socket)

    partial_hash =
      if partial, do: Partial.hash_for_view_and_name(view, partial), else: index(socket)

    Partial.all_assigns(partial_hash)
  end

  @doc """
  Cleans up the assigns cache for the current event handler process.

  Should be used when you want to re-read the assigns from the browser, for example when the other
  process could update the living assigns in the same time as current event handler runs.
  """
  @spec clean_cache() :: term
  def clean_cache() do
    Process.put(:__assigns_data, nil)
  end

  @spec assign_updates_js(map, String.t(), String.t()) :: [String.t()]
  defp assign_updates_js(assigns, partial, "document") do
    Enum.map(assigns, fn {k, v} ->
      "__drab.assigns[#{Drab.Core.encode_js(partial)}][#{Drab.Core.encode_js(k)}] = {document: '#{
        Drab.Live.Crypto.encode64(v)
      }'}"
    end)
  end

  defp assign_updates_js(assigns, partial, shared_commander_id) do
    Enum.map(assigns, fn {k, v} ->
      "__drab.assigns[#{Drab.Core.encode_js(partial)}][#{Drab.Core.encode_js(k)}][#{
        Drab.Core.encode_js(shared_commander_id)
      }] = '#{Drab.Live.Crypto.encode64(v)}'"
    end)
  end

  @spec drab_commander_id(Drab.Core.subject()) :: String.t()
  defp drab_commander_id(%Phoenix.Socket{} = socket) do
    socket.assigns[:__sender_drab_commander_id] || "document"
  end

  defp drab_commander_id(_), do: "document"

  @spec assigns_for_partial(
          Phoenix.Socket.t(),
          String.t() | atom,
          String.t() | atom,
          atom,
          map
        ) :: map | no_return
  defp assigns_for_partial(socket, partial, partial_name, assigns_type, assigns_data) do
    assigns =
      case Map.fetch(assigns_data[assigns_type], partial) do
        {:ok, val} ->
          val

        :error ->
          raise_partial_not_found(partial_name)
      end

    assigns =
      for {k, v} <- assigns, into: %{} do
        {
          k,
          case v[drab_commander_id(socket)] do
            # global value
            nil ->
              v["document"]

            x ->
              x
          end
        }
      end

    assigns
    |> Enum.map(&apply_conn_merge/1)
    |> Enum.into(%{})
  end

  defp apply_conn_merge({:conn, v}), do: {:conn, Drab.Live.Assign.merge(%Plug.Conn{}, v)}
  defp apply_conn_merge(other), do: other

  @spec index(Phoenix.Socket.t()) :: String.t()
  defp index(socket) do
    # assigns_and_index(socket)[:index]
    socket.assigns[:__drab_index]
  end

  @spec csrf_token(Drab.Core.subject()) :: String.t() | nil
  defp csrf_token(%Phoenix.Socket{} = socket) do
    socket.assigns[:__csrf_token]
  end

  defp csrf_token(_), do: nil

  @spec assigns_and_nodrab(Drab.Core.subject()) :: {atom, map}
  defp assigns_and_nodrab(%Phoenix.Socket{} = socket) do
    case {Process.get(:__drab_event_handler_or_callback), Process.get(:__assigns_data)} do
      {true, nil} ->
        {:ok, decrypted} = decrypted_from_browser(socket)
        Process.put(:__assigns_data, decrypted)
        {:ok, decrypted}

      {true, value} ->
        {:ok, value}

      # the other case (it is test or IEx session)
      {_, _} ->
        decrypted_from_browser(socket)
    end
  end

  # for broadcasting - this is OK, because in case of subject we need to provide ALL the assigns
  defp assigns_and_nodrab(_) do
    {:ok, %{}}
  end

  @spec update_assigns_cache(map, String.t(), String.t(), map) :: term() | nil
  defp update_assigns_cache(assigns_to_update, partial_hash, shared_commander_id, cache) do
    updated_assigns =
      for {assign_name, assign_value} <- assigns_to_update, into: %{} do
        {assign_name, %{shared_commander_id => assign_value}}
      end

    cached_assigns = cache[:assigns]
    cache_for_partial = cached_assigns[partial_hash]
    updated_assigns_for_partial = Map.merge(cache_for_partial, updated_assigns)
    updated_assigns_cache = Map.put(cached_assigns, partial_hash, updated_assigns_for_partial)
    Process.put(:__assigns_data, %{cache | assigns: updated_assigns_cache})
  end

  @pr "({assigns: __drab.assigns, nodrab: __drab.nodrab})"
  defp decrypted_from_browser(socket) do
    case exec_js(socket, @pr) do
      {:ok, ret} ->
        {:ok,
         %{
           :assigns => decrypted_assigns(ret["assigns"]),
           :nodrab => decrypted_assigns(ret["nodrab"])
         }}

      error ->
        error
    end
  end

  @spec decrypted_assigns(map) :: map
  defp decrypted_assigns(nil), do: %{}
  defp decrypted_assigns(assigns) do
    for {partial, partial_assigns} <- assigns, into: %{} do
      {partial,
       for {assign_name, assign_values} <- partial_assigns, into: %{} do
         {
           String.to_existing_atom(assign_name),
           for {shared_commander_id, assign_value} <- assign_values, into: %{} do
             {shared_commander_id, Drab.Live.Crypto.decode64(assign_value)}
           end
         }
       end}
    end
  end

  @spec raise_assign_not_found(atom, list) :: no_return
  defp raise_assign_not_found(assign, current_keys) do
    raise ArgumentError,
      message: """
      assign @#{assign} not found in Drab EEx template.

      Please make sure all proper assigns have been set. If this
      is a child template, ensure assigns are given explicitly by
      the parent template as they are not automatically forwarded.

      Available assigns:
      #{inspect(current_keys)}
      """
  end

  @spec raise_partial_not_found(String.t() | nil) :: no_return
  @doc false
  def raise_partial_not_found(path) do
    raise ArgumentError,
      message: """
      template `#{path || "main"}` not found.

      Please make sure this partial exists and has been compiled
      by Drab (has *.drab extension).

      If you want to poke assign to the partial which belong to
      the other view, you need to specify the view name in `poke/4`.
      """
  end

  defp raise_if_read_only(assigns) do
    if Enum.member?(Keyword.keys(assigns), :conn) do
      raise ArgumentError,
        message: """
        assign `@conn` is read only.
        """
    end
  end

  defp raise_broadcast_poke_with_subject do
    raise ArgumentError,
      message: """
      `broadcast_poke` without given socket must be called with the following arguments:
      * view
      * template
      * using_assings option

      Example:
      iex> broadcast_poke same_action(MyApp.PageController, :mini), MyApp.PageView, "index.html",
           text: "changed text", using_assigns: [color: "red"]
      """
  end
end
