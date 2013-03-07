class Kandan.Data.Users
  @callbacks: { "change": [] }

  @all: ()->
    Kandan.Helpers.Users.all()

  @registerCallback: (event, callback)->
    @callbacks[event].push(callback)

  @runCallbacks: (event, data)->
    callback(data) for callback in @callbacks[event]

  @unregisterCallback: (event, callback)->
    delete @callbacks[@callbacks.indexOf(callback)]
    @callbacks.filter (element, index, array)->
      element!=undefined

  @currentUser: ()->
    Kandan.Helpers.Users.currentUser()
