# defmodule Mix.Tasks.Drab.Install.Js do
#   use Mix.Task

#   @shortdoc "Installs Drab javascript library"

#   @moduledoc """
#   Creates a softlink of drab.js library to web/static/js/drab.js

#       mix drab.install.js

#   To be removed in the future and replaced by npm package.
#   """

#     # cd web/static/js/
#     # ln -s ../../../deps/drab/web/static/js/drab.js drab.js

#   def run(_) do
#     Mix.shell.info "Getting deps"
#     Mix.shell.cmd "mix deps.get"
#     File.cd "web/static/js"
#     File.ln_s "../../../deps/drab/web/static/js/drab.js", "drab.js"
#     Mix.shell.info """
#     Created a link to drab.js in web/static/js
#     """
#     Mix.shell.cmd("ls -l drab.js")
#   end
# end
