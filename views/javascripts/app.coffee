$(document).ready(->
  Spine.Route.setup(history: true)
  app_ctrl = new AppCtrl(el: $(document))
)

#------------- Websocket ------------- 

class Websocket
  constructor: (host, port, handle, @handle_bad_sid) ->
    window.WEB_SOCKET_SWF_LOCATION = 'WebSocketMain.swf'

    @ws = new WebSocket("ws://#{host}:#{port}/")

    @ws.onclose = ->
      console.log("socket closed")

    @ws.onopen = ->
      console.log("connected...")
      handle()

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
      @handle_bad_sid() if data.status == 'badSession'
        
  
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
    '#auth':    '_auth'

  events:
    'click #login':   'login'
    'click #signup':  'signup'
    'click #logout':  'logout'

  constructor: (sel, @ws, @init_ctrls) ->
    super(el: $(sel))
    s = Session.first()
    user_login = s && s.login
    if user_login
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

  flush: ->
    @_profile.hide()
    @_auth.show()

#-------- UsersOnline --------

class UsersOnlineCtrl extends Spine.Controller
  elements:
    '#users_online': 'location'

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
    @location.show()
    @.render()

  render: ->
    users = (u.login for u in UserOnline.all())
    templ = $('#templ_users_online').html()
    compiled = _.template(templ)
    @location.empty()
    @location.append(compiled(users: users))
  
#-------- AvailableGames --------

class AvailableGamesCtrl extends Spine.Controller
  elements:
    '#available_games': 'location'

  constructor: (el, @ws) ->
    super(el: el)

  show: ->
    @location.show()

#-------- Maps editor --------

class MapsEditorCtrl extends Spine.Controller
  elements:
    '#maps_editor':             'location'
    '#maps_editor .list_maps':  'list_maps'
    '#maps_editor .map':        'map'
    '#name_map':                'name_map'
    '#width_map':               'width_map'
    '#height_map':              'height_map'
    '#btn_del_map':             'btn_del'

  events:
    'click #btn_new_map':       'create_map'
    'click #btn_del_map':       'remove_map'
    'click #btn_save_map':      'save_map'
    'click #btn_gen_map':       'gen_map'

  constructor: (el, @ws) ->
    super(el: el)

  show: ->
    @location.show()
    @ws.send(
      { 'cmd': 'getListMaps' },
      (req) =>
        @.render(req['maps'])
    )
    @.flush()

  flush: ->
    @map.empty()
    for el in ['name', 'width', 'height']
      @["#{el}_map"].val('')
    @list_maps.find('li').removeClass('selected')
    @btn_del.attr('disabled', 'disabled')

  render: (maps) ->
    Utils.compile_templ(
      '#templ_list_maps',
      @list_maps,
      { maps: maps }
    )
    @list_maps.find('li').each (i, el) =>
      $(el).on 'click', =>
        obj_el = $(el)
        obj_el.parent().find('li').removeClass('selected')
        obj_el.addClass('selected')

        @btn_del.removeAttr('disabled')

        @.load_map(Utils.strip(obj_el.html()))

  load_map: (name_map) ->
    @ws.send(
      { cmd: 'getMapParams', name: name_map },
      (map) =>
        @.init_map_params(name_map, map.width, map.height)
        @.render_map(map.width, map.height, map.structure)
    )

  init_map_params: (name, width, height) ->
    @name_map.val(name)
    @width_map.val(width)
    @height_map.val(height)

  render_map: (width, height, structure) ->
    Utils.compile_templ(
      '#templ_map',
      @map,
      { width: width, height: height  }
    )
    if structure?
      for cl in ['pl1', 'pl2', 'obst']
        for i in structure[cl]
          $("#cell_#{i}").addClass(cl)

  remove_map: ->
    obj = @list_maps.find('li.selected')
    n = Utils.strip(obj.html())
    @ws.send(
      { cmd: 'destroyMap', name: n },
      =>
        obj.remove()
        @.flush()
    )
  
  create_map: ->
    @.flush()

  save_map: ->
    #Validate map
  
  gen_map: ->
    #Validate inputs
    @.render_map(
      parseInt(@width_map.val()),
      parseInt(@height_map.val())
    )

#-------- App --------

class AppCtrl extends Spine.Controller
  elements:
    '#content': 'content'

  events:
    'click #btn_users_online':    'nav_location'
    'click #btn_available_games': 'nav_location'
    'click #btn_maps_editor':     'nav_location'

  constructor: ->
    super
    @ws = new Websocket(
      'localhost',
      9001,
      ( =>      #After opened websocket
        @.restore_session()
        @auth_ctrl = new AuthCtrl '#top_menu', @ws, =>
          @.init_ctrls()
      ),
      (=>       #After status 'badSession'
        Session.destroyAll()
        @auth_ctrl.flush()
      )
    )

  init_ctrls: ->
    @ctrls =
      users_online: new UsersOnlineCtrl(@content, @ws)
      available_games: new AvailableGamesCtrl(@content, @ws)
      maps_editor: new MapsEditorCtrl(@content, @ws)

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

  @strip: (str) ->
    str.replace(/^\s+|\s+$/g, '')

  @compile_templ: (sel_templ, container, props) ->
    templ = $(sel_templ).html()
    compiled = _.template(templ)
    container.empty()
    container.append(compiled(props))

