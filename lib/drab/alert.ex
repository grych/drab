defmodule Drab.Alert do
  import Drab.Query

  @moduledoc """
  """

  @doc """
  """
  def alert(socket, message) do
    # TODO: move it to template
    html = """
    <div id="drabModal" class="modal fade" tabindex="-1" role="dialog">
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            <h4 class="modal-title">Modal title</h4>
          </div>
          <div class="modal-body">
            <p>One fine body&hellip;</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-primary">Save changes</button>
            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
          </div>
        </div><!-- /.modal-content -->
      </div><!-- /.modal-dialog -->
    </div><!-- /.modal -->
    """
    socket |> insert(html, append: "body")
    socket |> execjs("$('#drabModal').modal(); 1")
  end
end
