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

  typingStarts: ->
    @fayeClient.publish '/app/activities', {
      event: "user#state:typingStarts"
      extra: {}
      userId: Kandan.Helpers.Users.currentUser().id
      channelId: Kandan.Helpers.Channels.getActiveChannelId()
    }

  typingStops: (messagePresent) ->
    eventName = if messagePresent then 'typingStopsPresent' else 'typingStops'
    @fayeClient.publish '/app/activities', {
      event: "user#state:#{eventName}"
      extra: {}
      userId: Kandan.Helpers.Users.currentUser().id
      channelId: Kandan.Helpers.Channels.getActiveChannelId()
    }

  blurred: ->
    @fayeClient.publish '/app/activities', {
      event: "user#state:blurred"
      extra: {}
      userId: Kandan.Helpers.Users.currentUser().id
      channelId: Kandan.Helpers.Channels.getActiveChannelId()
    }

  focussed: ->
    @fayeClient.publish '/app/activities', {
      event: "user#state:focussed"
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
    if eventName.match(/connect/)
      $(document).data('active-users', data.extra.active_users)
      Kandan.Data.ActiveUsers.runCallbacks("change", data)
    else if eventName.match(/state/)
      $(document).data('user-states', {}) unless $(document).data('user-states')
      $(document).data('user-channels', {}) unless $(document).data('user-channels')
      state = switch(eventName)
        when 'state:typingStarts' then 'typing'
        when 'state:typingStops' then ''
        when 'state:typingStopsPresent' then 'paused'
        when 'state:blurred' then 'blurred'
        when 'state:focussed' then 'here'
      $(document).data('user-states')[data.userId] = state
      $(document).data('user-channels')[data.userId] = data.channelId
      data.extra.active_users = $(document).data('active-users')
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
