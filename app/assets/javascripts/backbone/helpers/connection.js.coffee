class Kandan.Helpers.Connection

  @getStatus: ->
    $(document).data("connection-status")

  @setStatus: (status) ->
    if (lastStatus = @getStatus()) != status
      Kandan.Data.Connection.statusTransition(lastStatus, status)
      $(document).data("connection-status", status)
