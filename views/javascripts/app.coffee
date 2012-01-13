$(document).ready(->
  Spine.Route.setup(history: true)
  app_ctrl = new AppCtrl(el: $(document))
)

#------------- Websocket ------------- 

class Websocket
  constructor: (host, port, conn_handler, @handle_bad_sid) ->
    window.WEB_SOCKET_SWF_LOCATION = 'WebSocketMain.swf'

    @ws = new WebSocket("ws://#{host}:#{port}/")

    @ws.onclose = ->
      console.log("socket closed")

    @ws.onopen = ->
      console.log("connected...")
      conn_handler()

    @ws.onmessage = $.proxy(@.handle, @)

    @queue = []
    @subscriptions = []

  handle: (resp) ->
    data = $.parseJSON(resp.data)
    console.log(data)

    if data['cmd'] && (h = @subscriptions[data['cmd']])
      h(data)
      return

    handler = @queue[0]
    @queue = @queue[1..@queue.length]

    if data.status == 'ok'
      handler(data)
    else
      alert(data.message)
      @handle_bad_sid() if data.status == 'badSession'
  
  subscribe: (cmd, func) ->
    console.log("Subscribe: #{cmd}")
    @subscriptions[cmd] = func

  unsubscribe: (cmd) ->
    console.log("Unsubscribe #{cmd}")
    delete @subscriptions[cmd]

  unsubscribe_all: ->
    console.log('Unsubscribe all')
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

class UserOnline extends Spine.Model
  @configure 'UserOnline', 'login'

class AvailableGame extends Spine.Model
  @configure 'AvailableGame', 'name'

class Map extends Spine.Model
  @configure 'Map', 'name'

class Army extends Spine.Model
  @configure 'Army', 'name'


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
      Session.deleteAll()
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

        @ws.unsubscribe_all()
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
    '#users_online': '_location'

  constructor: (el, @ws) ->
    super(el: el)

    UserOnline.destroyAll()

    @ws.send { 'cmd': 'getUsersOnline' }, (req) =>
      UserOnline.create(login: u) for u in req['users']

    @ws.subscribe 'addUserOnline', (data) ->
      UserOnline.create(login: data.login)

    @ws.subscribe 'delUserOnline', (data) ->
      user = UserOnline.findByAttribute('login', data.login)
      UserOnline.destroy(user.id)

  show_content: ->
    @_location.show()
    @.render()

  hide_content: ->
    @_location.hide()

  render: ->
    Utils.compile_templ(
      '#templ_resources',
      @_location,
      {
        header: 'Users online'
        resources: (u.login for u in UserOnline.all())
      }
    )
  
#-------- AvailableGames --------

class AvailableGamesCtrl extends Spine.Controller
  elements:
    '#available_games': '_location'

  constructor: (el, @ws) ->
    super(el: el)

    AvailableGame.destroyAll()

    @ws.send { 'cmd': 'getAvailableGames' }, (req) =>
      AvailableGame.create(name: g) for g in req['games']

    @ws.subscribe 'addAvailableGame', (data) ->
      AvailableGame.create(name: data.name)

    @ws.subscribe 'delAvailableGame', (data) ->
      user = AvailableGame.findByAttribute('name', data.name)
      AvailableGame.destroy(user.id)

  show_content: ->
    @_location.show()
    @.render()

  hide_content: ->
    @_location.hide()

  render: ->
    Utils.compile_templ(
      '#templ_resources',
      @_location,
      {
        header: 'Available games'
        resources: (g.name for g in AvailableGame.all())
      }
    )

#-------- Maps editor --------

class MapsEditorCtrl extends Spine.Controller
  elements:
    '#maps_editor':                 '_location'
    '#maps_editor .list_maps':      '_list_maps'
    '#maps_editor .map':            '_map'
    '#name_map':                    '_name_map'
    '#width_map':                   '_width_map'
    '#height_map':                  '_height_map'
    '#maps_editor .btn_del':        '_btn_del'
    '#maps_editor .btn_save':       '_btn_save'
    '#btn_clean_map':               '_btn_clean'
    '#maps_editor .tools':          '_tools'

  events:
    'click .btn_new':                     'create_map'
    'click .btn_del':                     'remove_map'
    'click .btn_save':                    'save_map'

    'click #btn_gen_map':                 'generate_map'
    'click #btn_clean_map':               'clean_map'

    'click #maps_editor .tools li':       'select_tool'
    'click #maps_editor .map .map_cell':  'set_map_cell'

  constructor: (el, @ws) ->
    super(el: el)
    @is_new = true
    for el in [@_width_map, @_height_map]
      el.force_num_only($.proxy(@.generate_map, @))


  show_content: ->
    @_location.show()
    Map.deleteAll()
    @ws.send { 'cmd': 'getListMaps' }, (req) =>
        Map.create(name: m) for m in req['maps']
        @.render_list()
    @.flush()

  hide_content: ->
    obj.empty() for obj in [@_map, @_list_maps]
    @_location.hide()


  flush: ->
    @_map.empty()
    for el in ['name', 'width', 'height']
      @["_#{el}_map"].val('')
    for obj in [@_list_maps, @_tools]
      obj.find('li').removeClass('selected')
    for btn in [@_btn_del, @_btn_save, @_btn_clean]
      btn.attr('disabled', 'disabled')


  render_list: (map_selected) ->
    Utils.compile_templ(
      '#templ_list',
      @_list_maps,
      { list: Map.all(), el_selected: map_selected }
    )
    @_list_maps.find('li').on 'click', (event) =>
      obj = $(event.target)
      @is_new = false
      Utils.select_li(obj)
      @.load_map(Utils.strip(obj.html()))


  load_map: (name_map) ->
    RMap.load @ws, name_map, (map) =>
      @.init_map_params(name_map, map.width, map.height)
      @.render_map(map.width, map.height, map.structure)


  init_map_params: (name, width, height) ->
    @_name_map.val(name)
    @_width_map.val(width)
    @_height_map.val(height)


  render_map: (width, height, structure) ->
    RMap.render(@_map, width, height, structure)

    Utils.select_li(@_tools.find('li:first'))
    for btn in [@_btn_del, @_btn_save, @_btn_clean]
      btn.removeAttr('disabled')

    @_last_width = width


  remove_map: ->
    obj = @_list_maps.find('li.selected')
    n = Utils.strip(obj.html())
    @ws.send { cmd: 'destroyMap', name: n }, =>
      Map.destroy(Map.findByAttribute('name', n).id)
      @.render_list()
      @.flush()

  
  create_map: ->
    @.flush()
    @is_new = true


  save_map: ->
    #Validate inputs
    #Validate map
    make_a = (cl) =>
      (
        for el in @_map.find(".map_cell.#{cl}")
          parseInt($(el).attr('id').slice(5))
      )

    req =
      cmd: if @is_new then 'createMap' else 'editMap'
      name: @_name_map.val()
      width: parseInt(@_width_map.val())
      height: parseInt(@_height_map.val())
      structure:
        pl1: make_a('pl1')
        pl2: make_a('pl2')
        obst: make_a('obst')

    if @is_new
      req['cmd'] = 'createMap'
      handler = =>
        Map.create(name: @_name_map.val())
        @.render_list(@_name_map.val())
    else
      req['cmd'] = 'editMap'
      handler = =>
        console.log('MAP SAVED!!')

    @ws.send(req, handler)

  
  generate_map: ->
    #Validate inputs
    width = parseInt(@_width_map.val())
    height = parseInt(@_height_map.val())
    
    d = width - @_last_width

    structure = {}
    for k in RMap.cell_classes
      structure[k] = []
      s = 0
      @_map.find(".map_cell.#{k}").each (i, el) =>
        i = parseInt($(el).attr('id').slice(5))
        j = Math.floor(i / @_last_width)
        c = i - j * @_last_width
        if c < width
          structure[k].push(i + j * d)

    @.render_map(width, height, structure)


  clean_map: ->
    @_map.find('.map_cell').removeClass('pl1 pl2 obst')


  select_tool: (event) ->
    Utils.select_li($(event.target))


  set_map_cell: (event) ->
    obj_cell = $(event.target)
    t = @_tools.find('li.selected .map_cell')
    tool_cl = t.attr('class').split(' ')[1] || ''
    obj_cell.attr('class', "map_cell #{tool_cl}")


#-------- Armies editor --------


#-------- GameCreationCtrl --------

class GameCreationCtrl extends Spine.Controller
  elements:
    '#game_creation':               '_location'

    '#game_creation .list_armies':  '_list_armies'
    '#game_creation .list_maps':    '_list_maps'

    '#game_creation .map':          '_map'
    '#game_creation .army':         '_army'

    '#game_creation .btn_create':   '_btn_create'

  events:
    'click #game_creation .btn_create': 'create_game'

  constructor: (el, @ws) ->
    super(el: el)

  show_content: ->
    @_location.show()
    @.load_list(
      'armies', Army, @_list_armies, $.proxy(@.load_army, @))
    @.load_list(
      'maps', Map, @_list_maps, $.proxy(@.load_map, @))

  hide_content: ->
    for obj in [@_map, @_list_armies, @_list_maps]
      obj.empty()
    obj.empty() for obj in [@_army, @_map]
    @_location.hide()

  load_list: (res, model, cont, handler) ->
    model.deleteAll()
    @ws.send { 'cmd': "getListAll#{Utils.capitalize(res)}" }, (req) =>
      model.create(name: el) for el in req[res]

      Utils.compile_templ(
        '#templ_list',
        cont,
        { list: model.all(), el_selected: null }
      )

      cont.find('li').on 'click', (event) =>
        obj = $(event.target)
        Utils.select_li(obj)
        handler(Utils.strip(obj.html()))

  load_map: (name_map) ->
    RMap.load @ws, name_map, (map) =>
      console.log(map)
      RMap.render(
        @_map, map.width, map.height, map.structure)

  load_army: (name_army) ->
    RArmy.load @ws, name_army, (army) =>
      console.log(army)
      RArmy.render(@_army, army.units)

  create_game: ->
    #Validate
    for s in ['available_games', 'game_creation', 'play_ai']
      $("#btn_#{s}").hide()

#-------- App --------

class AppCtrl extends Spine.Controller
  elements:
    '#content': '_content'

  events:
    'click #btn_users_online':    'nav_location'
    'click #btn_available_games': 'nav_location'
    'click #btn_maps_editor':     'nav_location'
    'click #btn_game_creation':   'nav_location'

  constructor: ->
    super
    @ws = new Websocket(
      'localhost',
      9001,
      (=>      #After opened websocket
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
      users_online:     new UsersOnlineCtrl(@_content, @ws)
      available_games:  new AvailableGamesCtrl(@_content, @ws)
      maps_editor:      new MapsEditorCtrl(@_content, @ws)
      game_creation:    new GameCreationCtrl(@_content, @ws)

  restore_session: ->
    data = $.parseJSON(sessionStorage.getItem('Session'))
    sessionStorage.removeItem('Session')
    if data?
      for rec in data
        Session.create
          login: rec.login
          sid: rec.sid

  nav_location: (event) ->
    v.hide_content() for k, v of @ctrls
    ctrl = event.handleObj.selector.slice(5)
    @ctrls[ctrl].show_content()

#------------- Resources -------------

class RMap
  @cell_classes = ['pl1', 'pl2', 'obst']

  @load: (@ws, name_map, handler) ->
    @ws.send(
      { cmd: 'getMapParams', name: name_map },
      handler
    )

  @render: (cont, width, height, structure) ->
    Utils.compile_templ(
      '#templ_map',
      cont,
      { width: width, height: height  }
    )
    if structure?
      for cl in @.cell_classes
        for i in structure[cl]
          $("#cell_#{i}").addClass(cl)

class RArmy
  @load: (@ws, name_army, handler) ->
    @ws.send(
      { cmd: 'getArmyUnits', name: name_army },
      handler
    )

  @render: (cont, units) ->
    u = ({ unit: k, count: v } for k, v of units)
    console.log(u)
    Utils.compile_templ(
      '#templ_army',
      cont,
      { units: u, count: u.length, col_count: 3 }
    )

#------------- Utils -------------

class Utils
  @capitalize: (str) ->
    str.slice(0, 1).toUpperCase() + str.slice(1)

  @strip: (str) ->
    str.replace(/^\s+|\s+$/g, '')

  @compile_templ: (sel_templ, container, options) ->
    templ = $(sel_templ).html()
    compiled = _.template(templ)
    container.empty().append(compiled(options))

  @select_li: (obj_li) ->
    obj_li.parent().find('li').removeClass('selected')
    obj_li.addClass('selected')

  @obj_len: (obj) ->
    res = 0
    res += 1 for k, v of obj
    res

#------------- jQuery functions -------------

jQuery.fn.force_num_only = (enter_handler) ->
  @.each ->
    $(@).on 'keydown', (e) ->
      key = e.charCode || e.keyCode || 0

      if e.shiftKey
        return key in [37..40] || key in [35, 36]

      if (key == 13)
        enter_handler()
        return true

      return (
        key in [8, 9, 46, 36, 35] ||
        key in [37..40] ||
        key in [48..57] ||
        key in [96..105]
      )

