$(document).ready(->
  Spine.Route.setup(history: true)
  app_ctrl = new AppCtrl(el: $(document))
)

#------------- Websocket ------------- 

class Websocket
  constructor: (host, port) ->
    WEB_SOCKET_SWF_LOCATION = '/WebSocketMain.swf'
    @ws = new WebSocket("ws://#{host}:#{port}/")

    @ws.onclose = ->
      console.log("socket closed")

    @ws.onopen = ->
      console.log("connected...")

    @ws.onmessage = (msg) =>
      @.handle(msg)

    @queue = []
    @subscriptions = []

  handle: (resp) ->
    data = $.parseJSON(resp.data)
    console.log(data)

    if data['cmd'] && (h = @subscriptions[data['cmd']])
      h(data)
      return

    if data.status == 'ok'
      handler = @queue[0]
      @queue = @queue[1..@queue.length]
      handler(data)
    else
      alert(data.message)
  
  subscribe: (cmd, func) ->
    console.log("Subscribe: #{cmd}")
    @subscriptions[cmd] = func

  unsubscribe: ->
    console.log('Unsubscribe')
    @subscriptions = {}

  auth: (req, handler) ->
    @queue.push(handler)
    @ws.send(JSON.stringify(req))

  send: (req, handler) ->
    s = Session.first()
    req.sid = s.sid
    @queue.push(handler)
    @ws.send(JSON.stringify(req))

#------------- Models ------------- 

class Session extends Spine.Model
  @configure 'Session', 'login', 'sid'
  @extend Spine.Model.Session

#  @restore: ->

class UserOnline extends Spine.Model
  @configure 'UserOnline', 'login'
  @extend Spine.Model.Session

class AvailableGame extends Spine.Model
  @configure 'AvailableGame', 'name'
  @extend Spine.Model.Session

#------------- Controllers -------------

#-------- Auth --------

class AuthCtrl extends Spine.Controller
  elements:
    '#profile': '_profile'
    '#auth': '_auth'

  events:
    'click #login': 'login'
    'click #signup': 'signup'
    'click #logout': 'logout'

  constructor: (sel, @ws, user_login, @init_ctrls) ->
    super(el: $(sel))
    if user_login?
      $('#user_login').html(user_login)
      @_profile.show()
      @init_ctrls()
    else
      @_auth.show()

  login: ->
    @.show_modal('login')

  signup: ->
    @.show_modal('signup')

  logout: ->
    @ws.send(
      { cmd: 'logout' },
      =>
        @_profile.hide()
        @_auth.show()
        Session.first().destroy()
        UserOnline.destroyAll()
        @ws.unsubscribe()
    )

  show_modal: (cmd) ->
    template = $('#templ_modal_auth').html()
    compiled = _.template(template)
    $('body').append(compiled(
      header: Utils.capitalize(cmd)
    ))

    obj = $('#modal_auth')

    obj.on 'hidden', ->
      $(@).remove()

    obj.modal
      backdrop: true,
      keyboard: true,
      show: true
    
    obj.find('.cancel').on 'click', =>
      obj.modal('hide')

    obj.find('.apply').on 'click', =>
      @.auth(
        cmd,
        obj.find('input.login').val(),
        obj.find('input.password').val(),
      )

  auth: (cmd, login, passw) ->
    @ws.auth(
      {
        cmd: cmd,
        login: login,
        password: passw
      },
      (req) =>
        $('#modal_auth').modal('hide')
        Session.create
          login: req.login,
          sid: req.sid

        $('#user_login').html(req.login)
        @_auth.hide()
        @_profile.show()

        @init_ctrls()
    )

#-------- UsersOnline --------

class UsersOnlineCtrl extends Spine.Controller
  elements:
    '#users_online': 'users_online'

  constructor: (el, @ws) ->
    super(el: el)

    UserOnline.destroyAll()

    @ws.send(
      { 'cmd': 'getUsersOnline' },
      (req) =>
        users = req['users']
        for u in users
          UserOnline.create(login: u)
    )

    @ws.subscribe(
      'addUserOnline',
      (data) ->
        UserOnline.create(login: data.login)
    )

    @ws.subscribe(
      'delUserOnline',
      (data) ->
        user = UserOnline.findByAttribute('login', data.login)
        UserOnline.destroy(user.id)
    )

  show: ->
    @users_online.show()
  
#-------- AvailableGames --------

class AvailableGamesCtrl extends Spine.Controller
  elements:
    '#available_games': 'available_games'

  constructor: (el, @ws) ->
    super(el: el)

  show: ->
    @available_games.show()

#-------- App --------

class AppCtrl extends Spine.Controller
  elements:
    '#content': 'content'

  events:
    'click #btn_users_online':    'nav_location'
    'click #btn_available_games': 'nav_location'

  constructor: ->
    super
    @ws = new Websocket('localhost', 9001)

    @.restore_session()
    s = Session.first()

    @auth_ctrl = new AuthCtrl '#top_menu', @ws, s && s.login, =>
      @.init_ctrls()

  init_ctrls: ->
    @ctrls =
      users_online: new UsersOnlineCtrl(@content, @ws)
      available_games: new AvailableGamesCtrl(@content, @ws)

  restore_session: ->
    data = $.parseJSON(sessionStorage.getItem('Session'))
    sessionStorage.removeItem('Session')
    if data?
      for rec in data
        Session.create
          login: rec.login
          sid: rec.sid

  hide_all: ->
    @content.children().hide()

  nav_location: (event) ->
    ctrl = event.handleObj.selector.slice(5)
    @.hide_all()
    @ctrls[ctrl].show()

#------------- Utils -------------

class Utils
  @capitalize: (str) ->
    str.slice(0, 1).toUpperCase() + str.slice(1)

