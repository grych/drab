# defmodule Mix.Tasks.Drab.Gen.Cipher do
#   use Mix.Task

#   @shortdoc "Generates a Cipher part of config"

#   @moduledoc """
#   Generates a Cipher keys and add the to the config.

#       mix drab.gen.cipher

#   This will generate a config for Cipher and show it on the screen (will not modify any file).

#       mix drab.gen.cipher dev

#   This will generate a config for Cipher and add it to the `config/dev.exs` file.

#       mix drab.gen.cipher prod.secret

#   Analogically, it will add Cipher part to the `config/prod.secret.exs` file.
#   """

#   def run([]) do
#     Mix.shell.info """
#     Add the following line to your config file (config/dev.exs, config/prod.secret.exs etc):

#     #{generate_keys()}
#     """
#   end
#   def run(args) do
#     [config_file] = validate_args!(args)
#     config_file_path = "config/#{config_file}.exs"

#     keys = generate_keys()

#     unless File.exists?(config_file_path), do: file_unwritable!(config_file_path, "file does not exist", keys)
#     case File.open(config_file_path, [:append]) do
#       {:ok, file} -> IO.write(file, keys)
#       {:error, reason} -> file_unwritable!(config_file_path, reason, keys)
#     end

#     Mix.shell.info """
#     The following lines were added to your `#{config_file_path}`:
#     #{keys}
#     """
#   end

#   defp file_unwritable!(config_file_path, reason, keys) do
#     Mix.raise """
#       Can't open the config file: #{config_file_path} (#{reason}).
      
#       Please add the following:
#       #{keys}
      
#       manually to your real config file.
#         """
#   end

#   defp generate_keys() do
#     source_file_path = "drab.gen.cipher.exs"
#     binding = [keyphrase: random_string(),
#                ivphrase: random_string(),
#                magic_token: random_string()]

#     roots = Enum.map(paths(), &to_app_source(&1, "priv/templates/"))
#     source =
#         Enum.find_value(roots, fn root ->
#           source = Path.join(root, source_file_path)
#           if File.exists?(source), do: source
#         end)

#     EEx.eval_file(source, binding)  
#   end

#   defp validate_args!(args) do
#     unless length(args) == 1 do
#       Mix.raise """
#       mix drab.gen.cipher expects config file name:
#           mix drab.gen.cipher dev
#       """
#     end
#     args
#   end

#   defp random_string() do
#     :crypto.strong_rand_bytes(64) |> Base.encode64 |> binary_part(0, 64)
#   end

#   defp paths do
#     [".", :drab]
#   end

#   defp to_app_source(path, source_dir) when is_binary(path),
#     do: Path.join(path, source_dir)
#   defp to_app_source(app, source_dir) when is_atom(app),
#     do: Application.app_dir(app, source_dir)
# end
