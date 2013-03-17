class Kandan.Plugins.UserList

  @widget_title: "People"
  @widget_icon_url: "/assets/people_icon.png"
  @pluginNamespace: "Kandan.Plugins.UserList"

  @template: JST['user_list_user']

  @buildStatus: (presenceStatus, presenceIcon, typingStatus = 'none', typingIcon = 'pause') ->
    {
      presence: {
        class: presenceStatus
        description: if presenceStatus == 'here' then 'Here' else 'Away'
        icon: "icon-#{presenceIcon}"
      }
      typing: {
        class: typingStatus
        description: if typingStatus == 'active' then 'Typing' else 'Paused'
        icon: "icon-#{typingIcon}"
      }
    }

  @render: ($el)->
    $users = $("<div class='user_list'></div>")
    $el.next().hide();

    channelNames = {}
    channelNames[channel.id] = channel.name for channel in Kandan.Helpers.Channels.all()

    for user in Kandan.Data.ActiveUsers.all()
      displayName   = null
      displayName   = user.username # Defaults to username
      displayName ||= user.email # Revert to user email address if that's all we have
      isAdmin       = user.is_admin

      $(document).data('user-states', userStates = {}) unless userStates = $(document).data('user-states')
      userStateData = userStates[user.id]

      channelId = userStateData?.channelId || 1
      typingState = userStateData?.typing
      presenceState = userStateData?.presence

      status = if typingState == 'start'
        @buildStatus('here','circle','active','circle') #spin icon-spinner')
      else if presenceState == 'away'
        @buildStatus('idle','circle-blank')
      else if typingState == 'pause'
        @buildStatus('here','circle','inactive','circle-blank')
      else if presenceState == 'here'
        @buildStatus('here','circle')
      else
        @buildStatus('here','circle')
      $users.append @template {
        userId: user.id
        name: displayName
        isAdmin: isAdmin
        avatarUrl: Kandan.Helpers.Avatars.urlFor(user, {size: 40})
        badgeStyle: Kandan.options().admin_badge_style || 'default'
        channel: {
          name: channelNames[channelId]
          id: channelId
        }
        status: status
        atime: userStateData?.atime || new Date()
      }
    $el.html($users)

    # iterate again, as we can only set up timestamps after the
    # elements have been added to the DOM.
    for user in Kandan.Data.ActiveUsers.all()
      atime = userStates[user.id]?.atime || new Date()
      $lastSeenEl = $el.find(".last-seen-at.user-#{user.id}")
      $lastSeenEl.data("timestamp", atime)
      $lastSeenEl.data("timestamp-threshold", 30000)

    $el.find('.channel').bind 'click', ->
      channelId = $(@).attr('href').split('-')[1]
      tab = Kandan.Helpers.Channels.getTabIndexByChannelId(channelId)
      $("#kandan").tabs("option", "selected", tab)

  @init: ()->
    Kandan.Widgets.register @pluginNamespace
    Kandan.Data.ActiveUsers.registerCallback "change", ()=>
      Kandan.Widgets.render @pluginNamespace
