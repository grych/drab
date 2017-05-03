defmodule Drab.Timeout do
  defexception message: """
        Can't get the reply from the browser: timeout (#{Drab.config[:timeout]} ms).
        """
end
