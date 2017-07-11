defmodule Drab.Element do
  @moduledoc """
  """
  import Drab.Core
  require IEx

  @type t :: %Drab.Element{selector: binary, 
                        attributes: list, 
                        properties: list, 
                        html: String.t, 
                        text: String.t, 
                        value: any}
  defstruct selector: nil, attributes: [], properties: [], html: nil, text: nil, value: nil

  use DrabModule
  @doc false
  def js_templates(),  do: ["drab.events.js", "drab.element.js"]

  @doc false
  def transform_payload(payload, _state) do
    payload 
      |> Map.put_new("value", payload["val"])
      |> Map.put_new(:params, payload["form"])
  end

  @doc false
  # def transform_socket(socket, payload, state) do
  #   socket
  # end

  def query(socket, selector) do
    query(socket, selector, [])
  end

  def query(socket, selector, properties) when is_list(properties) do
    js = "Drab.query(#{encode_js(selector)}, #{encode_js(properties)})"
    case exec_js(socket, js) do
      {:ok, ret} -> {:ok, {selector, ret}}
      {:error, _} = error -> error
    end
  end

  def query(socket, selector, property) when is_binary(property) or is_atom(property) do
    query(socket, selector, [property])
  end


  def query!(socket, selector) do
    query!(socket, selector, [])
  end

  def query!(socket, selector, properties) when is_list(properties) do
    js = "Drab.query(#{encode_js(selector)}, #{encode_js(properties)})"
    {selector, exec_js!(socket, js)}
  end

  def query!(socket, selector, property) when is_binary(property) or is_atom(property) do
    query!(socket, selector, [property])
  end

end
