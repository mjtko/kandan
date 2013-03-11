class Kandan.Data.Connection
  @callbacks: { "softchange": [], "hardchange": [] }

  @registerCallback: (event, callback)->
    @callbacks[event].push(callback)

  @runCallbacks: (event, data)->
    callback(data) for callback in @callbacks[event]

  @unregisterCallback: (event, callback)->
    delete @callbacks[@callbacks.indexOf(callback)]
    @callbacks.filter (element, index, array)->
      element!=undefined

  @statusTransition: (lastStatus, nowStatus) ->
    clearTimeout @_timer if @_timer
    timerExpired = =>
      @runCallbacks('hardchange')
      @_timer = null
    @_timer = setTimeout timerExpired, 5000
