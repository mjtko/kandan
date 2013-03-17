class Kandan.Broadcasters.FayeBroadcaster

  constructor: ()->
    endpoint = $('body').data('kandan-config').broadcaster.config.endpoint
    @fayeClient = new Faye.Client(endpoint)

    @fayeClient.disable('websocket')
    authExtension = {
      outgoing: (message, callback)->
        if message.channel == "/meta/subscribe"
          message['ext'] = {
            auth_token: Kandan.Helpers.Users.currentUser().auth_token
          }
        callback(message)
    }
    @fayeClient.addExtension(authExtension)

    @fayeClient.bind "transport:down", =>
      @processEventsForConnection('down')
      console.log "Comm link to Cybertron is down!"

    @fayeClient.bind "transport:up", =>
      @processEventsForConnection('up')
      console.log "Comm link is up!"

    @fayeClient.subscribe "/app/activities", (data)=>
      [entityName, eventName] = data.event.split("#")
      @processEventsForUser(eventName, data)        if entityName == "user"
      @processEventsForChannel(eventName, data)     if entityName == "channel"
      @processEventsForAttachments(eventName, data) if entityName == "attachments"

    @fayeClient.subscribe '/app/sync', (data)=>
      $(document).data('user-states', userStates = {}) unless userStates = $(document).data('user-states')
      if data == 'request'
        # when we receive this message, we publish our current state information
        # this includes:
        #   1. presence state
        #   2. typing state
        #   3. current channel
        currentUserId = Kandan.Helpers.Users.currentUser().id
        userStateData = userStates[currentUserId]
        typingState = userStateData?.typing || 'stop'
        presenceState = userStateData?.presence || 'here'
        if presenceState == 'away'
          @blurred()
        else if typingState == 'start'
          @typingStarts()
        else if typingState == 'pause'
          @typingPauses()
        else
          @focussed()
        @fayeClient.publish '/app/sync', {
          atime: (userStateData?.atime || new Date()).getTime()
          userId: currentUserId
        }
      else
        userStates[data.userId].atime ?= new Date(data.atime)
        data.extra = { active_users: $(document).data('active-users') }
        Kandan.Data.ActiveUsers.runCallbacks("change", data)
    @fayeClient.publish '/app/sync', 'request'

  typingStarts: => @typingEvent('start')
  typingStops: => @typingEvent('stop')
  typingPauses: => @typingEvent('pause')
  blurred: => @presenceEvent('away')
  focussed: => @presenceEvent('here')

  typingEvent: (eventName) -> @publishUserEvent('typing', eventName)
  presenceEvent: (eventName) -> @publishUserEvent('presence', eventName)

  publishUserEvent: (eventType, eventName) ->
    @fayeClient.publish '/app/activities', {
      event: "user##{eventType}:#{eventName}"
      extra: {}
      userId: Kandan.Helpers.Users.currentUser().id
      channelId: Kandan.Helpers.Channels.getActiveChannelId()
    }

  processEventsForConnection: (eventName) ->
    Kandan.Helpers.Connection.setStatus(eventName)
    Kandan.Data.Connection.runCallbacks("softchange")

  processEventsForAttachments: (eventName, data)->
    Kandan.Helpers.Channels.addActivity(data.entity, Kandan.Helpers.Activities.ACTIVE_STATE)
    Kandan.Data.Attachments.runCallbacks("change", data)

  processEventsForUser: (eventName, data)->
    $(document).data('user-atimes', {}) unless $(document).data('user-atimes')
    if eventName.match(/connect/)
      $(document).data('active-users', data.extra.active_users)
    else if eventName.match(/presence/) or eventName.match(/typing/)
      $(document).data('user-states', userStates = {}) unless userStates = $(document).data('user-states')
      [stateType, state] = eventName.split(':')
      userStateData = userStates[data.userId] ?= {}
      userStateData.channelId = data.channelId
      userStateData[stateType] = state
      # typing start or triggering focus of the window ('here') cause
      # the access time to be updated
      if state == 'start' || state == 'here'
        userStateData.atime = new Date()
      data.extra.active_users = $(document).data('active-users')
    else
      return
    Kandan.Data.ActiveUsers.runCallbacks("change", data)

  processEventsForChannel: (eventName, data)->
    Kandan.Helpers.Channels.deleteChannelById(data.entity.id) if eventName == "delete"
    Kandan.Helpers.Channels.createChannelIfNotExists(channel: data.entity, channel_id: data.entity.id) if eventName == "create"

    # TODO this has to be implemented
    Kandan.Helpers.Channels.renameChannelById(data.entity.id, data.entity.name) if data.eventName == "update"


  subscribe: (channel)->
    subscription = @fayeClient.subscribe channel, (data)=>
      Kandan.Helpers.Channels.addActivity(data, Kandan.Helpers.Activities.ACTIVE_STATE)
    subscription.errback((data)->
      console.log "error", data
      alert "Oops! could not connect to the server"
    )
