defmodule Drab.Endpoint do
  @moduledoc ~S"""
  To enable drab, use the following clause in your projects `lib/endpoint.ex`:

      use Drab.Endpoint
  """

  defmacro __using__(_options) do
    quote do
      # Module.register_attribute __MODULE__, :additional_channels, accumulate: true

      # unquote do 
      #   if options[:add_channels] do
      #     options[:add_channels] |> Enum.map(fn {channel, module} -> 
      #       quote bind_quoted: [channel: channel, module: module] do
      #         # socket unquote(channel), unquote(module)
      #         @additional_channels {channel, module}
      #       end
      #     end)
      #   end
      # end

      socket Drab.config.socket, Drab.Socket
      # do
      #   channel "drab:*", Drab.Channel
      # end


    end
  end

  # defmacro __before_compile__(env) do
  #   additional_channels = Module.get_attribute(env.module, :additional_channels)
  #   quote do
  #     def __additional_channels__, do: unquote(additional_channels)
  #   end

  # end


  # defmacro drab(channel, module) do
  #   quote do
  #     @additional_channels {unquote(channel), unquote(module)}
  #   end
  # end

      # def __additional_channels__() do
      #   @additional_channels
      # end
end
