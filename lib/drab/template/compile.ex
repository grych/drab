defmodule Drab.Template.Compile do
  @moduledoc false

  @doc false
  defmacro create_compiled_template(template_path, template_name) do
    quote bind_quoted: binding() do
      IO.puts "compiling template: #{(template_path)}"
      compiled = EEx.compile_file(template_path)
      def compiled_template(unquote(template_name)) do
        unquote(compiled)
      end
    end  
  end
end
