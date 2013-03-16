class Kandan.Views.Chatbox extends Backbone.View

  template:  JST['chatbox']
  tagName:   'div'
  className: 'chatbox'


  events:
    "keypress .chat-input": 'postMessageOnEnter'
    "click    .post"      : 'postMessage'


  postMessageOnEnter: (event)->
    # If a modifier key is used with enter, messages are not posted.
    # This allows the chatbox textarea to behave predictably, inline
    # with usual form semantics (ie. ctrl+enter etc. generates a new
    # line).
    if event.keyCode == 13 && !event.metaKey && !event.shiftKey && !event.altKey && !event.ctrlKey
      @postMessage(event)
      event.preventDefault()


  postMessage: (event)->
    $chatbox = $(event.target).parent().find(".chat-input")
    chatInput = $chatbox.val()
    return false if chatInput.trim().length==0

    activity = new Kandan.Models.Activity({
      'content':    chatInput,
      'action':     'message',
      'channel_id': @channel.get('id')
    })

    $chatbox.val("")

    Kandan.broadcaster.typingStops(false)
    activity.save({},{success: (model, response)->
      Kandan.Helpers.Channels.addActivity(
        _.extend(activity.toJSON(), {cid: activity.cid, user: Kandan.Data.Users.currentUser()}, created_at: new Date()),
        Kandan.Helpers.Activities.ACTIVE_STATE,
        true
      )

      $("#activity-c#{model.cid}").attr("id", "activity-#{model.get('id')}")
      theId = Kandan.Helpers.Channels.getActiveChannelId()
      Kandan.Helpers.Channels.scrollToLatestMessage(theId)

    })

  render: ()->
    @channel = @options.channel
    connectionStatus = Kandan.Helpers.Connection.getStatus()
    if connectionStatus == 'down'
      connectionIcon = 'minus-sign'
    else
      connectionIcon = 'bolt'
    $el = $(@el)
    $el.html @template {
      connectionStatus: connectionStatus
      connectionIcon: connectionIcon
    }
    $el.find('.chat-input').inputHistory {
      size: 20
    }
    keyPressTimer = =>
      if $el.find('.chat-input').val() == ''
        Kandan.broadcaster.typingStops(false)
        console.log 'typing stops, no message'
      else
        Kandan.broadcaster.typingStops(true)
        console.log 'typing stops, message'
      delete @_keyPressTimer

    $el.bind 'keydown', =>
      if @_keyPressTimer?
        clearTimeout @_keyPressTimer
      else
        console.log 'typing starts'
        Kandan.broadcaster.typingStarts()
      @_keyPressTimer = setTimeout keyPressTimer, 1000
    @

  @updateChatStatus: (eventName) ->
    ->
      $postButton = $('.chatbox .post')
      if Kandan.Helpers.Connection.getStatus() == 'down'
        if eventName == 'soft'
          $postButton.html('Post <i class="icon-spinner icon-spin"></i>').
            removeClass('up down').addClass('maybe-down')
        else
          $postButton.html('Post <i class="icon-minus-sign"></i>').
          removeClass('maybe-down up').addClass('down')
      else
        $postButton.html('Post <i class="icon-bolt"></i>').
          removeClass('maybe-down down').addClass('up')
