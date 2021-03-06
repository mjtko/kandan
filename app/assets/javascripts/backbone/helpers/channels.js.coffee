class Kandan.Helpers.Channels
  @all: (options)->
    $(document).data("channels")

  @getCollection: ->
    $(document).data("channelsCollection")

  @setCollection: (collection)->
    $(document).data("channelsCollection", collection)
    $(document).data("channels", collection.toJSON())

  @options:
    autoScrollThreshold: 0.90

  @pastAutoScrollThreshold: (channelId)->
    currentPosition     = @currentScrollPosition channelId
    totalHeight         = $(document).height() # - $(window).height()
    scrollPercentage    = (currentPosition) / (totalHeight)
    scrollPercentage > @options.autoScrollThreshold

  @scrollToLatestMessage: (channelId)->
    if channelId
      theScrollArea = $('#channels-'+channelId)
      theScrollArea.animate {
        scrollTop: theScrollArea.prop('scrollHeight')
        easing: 'linear'
      }, 2000
    else
      $('.channels-pane').scrollTop($('.channels-pane').prop('scrollHeight'))

  @currentScrollPosition: (channelId)->
    $('.channels-pane').scrollTop()

  @channelActivitiesEl: (channelId)->
    $("#channel-activities-#{channelId}")

  @channelPaginationEl: (channelId)->
    $("#channels-#{channelId} .pagination")

  @selectedTab: ()->
    $("#kandan").tabs("option", "selected")

  @getActiveChannelId: ()->
    if $(document).data('active-channel-id') == undefined
      return $("#kandan .ui-tabs-panel")
        .eq(@selectedTab())
        .data("channel-id")
    else
      return $(document).data("active-channel-id")



  @confirmDeletion: ()->
    return confirm("Really delete the channel?")


  @flushActivities: (channelId)->
    $channelActivities = $("#channel-activities-#{channelId}")
    if $channelActivities.children().length == Kandan.options().per_page + 1
      $channelActivities.children().first().remove()
      oldest = $channelActivities.children().first().data("activity-id")
      $channelActivities.prev().data("oldest", oldest)
      @channelPaginationEl(channelId).show()


  @confirmAndDeleteChannel: (channel, tabIndex)->
    return false if @confirmDeletion() == false
    channel.destroy {
      success: ()=> #@removeChannelTab(tabIndex)
    }

  @removeChannelTab: (tabIndex)->
    $("#kandan").tabs("remove", tabIndex)

  @getChannelIdByTabIndex: (tabIndex)->
    $("#kandan .ui-tabs-panel")
      .eq(tabIndex)
      .data("channel-id")

  @getTabIndexByChannelId: (channelId)->
    $("#channels-#{channelId}").prevAll("div").length

  @deleteChannelById: (channelId)->
    if @channelExists(channelId)
      tabIndex = @getTabIndexByChannelId(channelId)
      @removeChannelTab(tabIndex)

  @deleteChannelByTabIndex: (tabIndex, deleted)->
    # NOTE gotcha, 0 index being passed a natural index from the html views
    deleted = deleted || false
    channelId = @getChannelIdByTabIndex(tabIndex)
    throw "NO CHANNEL ID" if channelId == undefined
    channel = new Kandan.Models.Channel({id: channelId})
    return @confirmAndDeleteChannel(channel, tabIndex) if not deleted


  @channelExists: (channelId)->
    return true if $("#channels-#{channelId}").length > 0
    false


  @createChannelArea: (channel)->
    channelArea = "#channels-#{channel.get('id')}"
    totalTabs = $("#kandan").tabs("length")
    $createTab = $("#create_channel").parents("li").detach()
    $("#kandan").tabs("add", channelArea, "#{channel.get("name")}", totalTabs)
    $createTab.appendTo("ul.ui-tabs-nav")
    $('#ui-tabs-1').remove()
    view = new Kandan.Views.ChannelPane({channel: channel})
    $newChannel = $(channelArea)
    view.render $newChannel
    $newChannel.addClass('ui-tabs-panel')

  @newActivityView: (activityAttributes)->
    activity = new Kandan.Models.Activity(activityAttributes)
    activityView  = new Kandan.Views.ShowActivity({activity: activity})
    return activityView

  @createChannelIfNotExists: (activityAttributes)->
    if activityAttributes.channel && (not @channelExists(activityAttributes.channel_id))
      @createChannelArea(new Kandan.Models.Channel(activityAttributes.channel))


  @addActivity: (activityAttributes, state, local)->
    local = local || false
    @createChannelIfNotExists(activityAttributes)

    if activityAttributes.channel_id
      @addMessage(activityAttributes, state, local)
    else
      @addNotification(activityAttributes)

    channelId = activityAttributes.channel_id || @getActiveChannelId()
    @scrollToLatestMessage(channelId) if @pastAutoScrollThreshold(channelId)


  @addMessage: (activityAttributes, state, local)->
    belongsToCurrentUser = ( activityAttributes.user.id == Kandan.Data.Users.currentUser().id )
    activityExists       = ( $("#activity-#{activityAttributes.id}").length > 0 )
    local = local || false

    if local || (!local && !belongsToCurrentUser && !activityExists)
      @channelActivitiesEl(activityAttributes.channel_id)
        .append(@newActivityView(activityAttributes).render().el)

    @flushActivities(activityAttributes.channel_id)

    if not local and @getActiveChannelId() == activityAttributes.channel_id and activityAttributes.action == "message" and Kandan.Helpers.Utils.browserTabFocused != true
      Kandan.Helpers.Utils.notifyInTitle()
      Kandan.Plugins.Notifications.playAudioNotification('channel')
      Kandan.Plugins.Notifications.displayNotification(activityAttributes.user.username || activityAttributes.user.email, activityAttributes.content)

      @setPaginationData(activityAttributes.channel_id)


  @addNotification: (activityAttributes)->
    $channelElements = $(".channel-activities")
    activityAttributes["created_at"] = new Date()
    for el in $channelElements
      $(el).append(@newActivityView(activityAttributes).render().el)
      @flushActivities($(el).closest(".ui-widget-content").data("channel-id"))
      @setPaginationData(activityAttributes.channel_id)


  @setPaginationState: (channelId, moreActivities, oldest)->
    @channelPaginationEl(channelId).data("oldest", oldest)
    if moreActivities == true
      @channelPaginationEl(channelId).show()
    else
      @channelPaginationEl(channelId).hide()


  @setPaginationData: (channelId)->
    $oldestActivity = @channelActivitiesEl(channelId).find(".activity").first()
    if $oldestActivity.length != 0
      @channelPaginationEl(channelId).data("oldest", $oldestActivity.data("activity-id"))
