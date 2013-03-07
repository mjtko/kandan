# The mentions plugin takes care of highlighting the @useranme and passing the users to the atwho plugin.
# The show_activities addMessage method is the responsible of changing the look of a message body when a user is mentioned
class Kandan.Plugins.Mentions
  @options:
    regex: /@\S*/g

    template: _.template '''<span class="mention"><%= mention %></span>'''

  @allUsers: []

  @init: ()->
    Kandan.Data.ActiveUsers.registerCallback "change", (data)=>
      @initUsersMentions(data.extra.active_users)

    Kandan.Data.Users.registerCallback "change", (data)=>
      @initAvailableUsers(data.extra.users)

    Kandan.Modifiers.register @options.regex, (message, state) =>
      for mention in message.content.match(@options.regex)
        if mention in @allUsers
          replacement = @options.template({mention: mention})
          message.content = message.content.replace(mention, replacement)

      return Kandan.Helpers.Activities.buildFromMessageTemplate(message)

  @initAvailableUsers: (users)=>
    @allUsers =  ("@#{u.username}" for u in users)

  @initUsersMentions: (activeUsers)->
    users = _.map activeUsers, (user)->
      user.username
    users.push "all"
    $(".chat-input").atwho("@", {data: users})
    return
