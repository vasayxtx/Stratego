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
    if data.status == 'ok'
      handler = @queue[0]
      @queue = @queue[1..@queue.length]
      handler(data)
    else
      alert(data.message)
  
  subscribe: (cmd, func) ->
    @subscription.push
      cmd: cmd,
      func: func

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
  @extend Spine.Model.Local

#  @restore: ->

class OnlineUser extends Spine.Model
  @configure 'OnlineUser', 'login'
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

  constructor: (sel, @ws, user_login) ->
    super(el: $(sel))
    if user_login?
      $('#user_login').html(user_login)
      @_profile.show()
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
    )

  show_modal: (cmd) ->
    template = $('#template_modal_auth').html()
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
    )

#-------- App --------

class AppCtrl extends Spine.Controller
  @extend Spine.Route

  constructor: ->
    super
    @ws = new Websocket('localhost', 9001)

    data = $.parseJSON(localStorage.getItem('Session'))
    localStorage.removeItem('Session')
    for rec in data
      Session.create
        login: rec.login
        sid: rec.sid

    s = Session.first()
    auth_ctrl = new AuthCtrl('#top_menu', @ws, s && s.login)

    @routes
      '/map-editor': ->
        console.log('map_editor')

#------------- Utils -------------

class Utils
  @capitalize: (str) ->
    str.slice(0, 1).toUpperCase() + str.slice(1)

