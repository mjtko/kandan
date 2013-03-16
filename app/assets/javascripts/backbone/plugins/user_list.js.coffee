class Kandan.Plugins.UserList

  @widget_title: "People"
  @widget_icon_url: "/assets/people_icon.png"
  @pluginNamespace: "Kandan.Plugins.UserList"

  @template: _.template '''
    <div class="user clearfix">
      <img class="avatar" src="<%= avatarUrl %>"/>
      <div class="x">
        <div class="name">
          <%= name %>
          <% if(admin) { %>
            &nbsp;<span class="badge badge-important">Admin</span>
          <% } %>
        </div>
        <a href="#channel-<%= channelId %>" class="channel"><%= channelName %></a>
      </div>
      <div class="status typing <%= typingStatus %>"></div>
      <div class="status presence <%= presenceStatus %>"></div>
    </div>
  '''

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

      switch($(document).data('user-states')?[user.id])
        when 'typing'
          presenceStatus = 'here'
          typingStatus = 'active'
        when 'paused'
          presenceStatus = 'here'
          typingStatus = 'inactive'
        when 'here'
          presenceStatus = 'here'
          typingStatus = 'inactive'
        when 'blurred'
          presenceStatus = 'idle'
          typingStatus = 'none'
        else
          presenceStatus = 'here'
          typingStatus = 'none'

      $users.append @template({
        name: displayName,
        admin: isAdmin,
        avatarUrl: Kandan.Helpers.Avatars.urlFor(user, {size: 25})
        channelName: channelNames[channelId]
        channelId: channelId
        presenceStatus: presenceStatus
        typingStatus: typingStatus
      })
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
