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

      channelId = $(document).data('user-channels')?[user.id] || 1

      status = switch($(document).data('user-states')?[user.id])
        when 'typing'
          @buildStatus('here','circle','active','circle') #spin icon-spinner')
        when 'paused'
          @buildStatus('here','circle','inactive','circle-blank')
        when 'here'
          @buildStatus('here','circle')
        when 'blurred'
          @buildStatus('idle','circle-blank')
        else
          @buildStatus('here','circle')

      $users.append @template {
        name: displayName,
        isAdmin: isAdmin,
        avatarUrl: Kandan.Helpers.Avatars.urlFor(user, {size: 40})
        badgeStyle: Kandan.options().admin_badge_style || 'default'
        channel: {
          name: channelNames[channelId]
          id: channelId
        }
        status: status
      }
    $el.html($users)
    $el.find('.channel').bind 'click', ->
      channelId = $(@).attr('href').split('-')[1]
      console.log "switch to channel", channelId
      tab = Kandan.Helpers.Channels.getTabIndexByChannelId(channelId)
      $("#kandan").tabs("option", "selected", tab)

  @init: ()->
    Kandan.Widgets.register @pluginNamespace
    Kandan.Data.ActiveUsers.registerCallback "change", ()=>
      Kandan.Widgets.render @pluginNamespace
