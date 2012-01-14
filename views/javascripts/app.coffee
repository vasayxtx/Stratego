$(document).ready(->#
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
  @configure 'Session', 'login', 'sid', 'location'
  @extend Spine.Model.Session

  @remove: ->
    sessionStorage.removeItem('Session')
    Session.deleteAll()

  @write_location: (loc) ->
    s = @.first()
    s.location = loc
    s.save()

class Game extends Spine.Model
  @configure 'Game', 'name', 'map', 'army', 'status'
  @extend Spine.Model.Session

  @remove: ->
    sessionStorage.removeItem('Game')
    Game.deleteAll()

  @write_status: (status) ->
    g = @.first()
    g.status = status
    g.save()


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
    '#user_login':  '_user_login'

  events:
    'click #login':   'login'
    'click #signup':  'signup'
    'click #logout':  'logout'

  constructor: (sel, @ws, @handler_login, @handler_logout) ->
    super(el: $(sel))

    s = Session.first()
    if s && s.login && s.sid
      @ws.send { cmd: 'checkSid' }, =>
        @_user_login.html(s.login)
        @handler_login()
    else
      @handler_logout()

  login: ->
    @.show_modal('login')

  signup: ->
    @.show_modal('signup')

  logout: ->
    @ws.send(
      { cmd: 'logout' },
      $.proxy(@handler_logout, @)
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

        Session.remove()
        Session.create
          login: req.login
          sid: req.sid
          location: 'about_project'

        @_user_login.html(req.login)
        @handler_login()
    )



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
    '#available_games':                 '_location'
    '#available_games .list_games':     '_list_games'

    '#available_games .map':            '_map'
    '#available_games .army':           '_army'
    '#available_games .army_panel h3':  '_name_army'
    '#available_games .map_panel h3':   '_name_map'

  events:
    'click #available_games #btn_join_game':  'join_game'

  constructor: (el, @ws, @ctrl_game) ->
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
    @.render_list()

  hide_content: ->
    @_location.hide()
    a = [@_map, @_army, @_name_army, @_name_map]
    obj.empty() for obj in a

  render_list: ->
    Utils.compile_templ(
      '#templ_list',
      @_list_games,
      { list: AvailableGame.all(), el_selected: null }
    )
    @_list_games.find('li').on 'click', (event) =>
      obj = $(event.target)
      Utils.select_li(obj)
      @.load_game(Utils.strip(obj.html()))

  load_game: (name_game) ->
    @ws.send(
      {
        cmd: 'getGameParams',
        name: name_game
      },
      (game) =>
        army = game.army
        RArmy.render(@_army, army.units)
        @_name_army.html(army.name)
        map = game.map
        RMap.render(@_map, map.width, map.height, map.structure)
        @_name_map.html(map.name)
    )

  join_game: ->
    name_game = Utils.get_selected(@_list_games)
    @ws.send(
      {
        cmd: 'joinGame'
        name: name_game
      },
      =>
        Game.remove()
        Game.create
          name: name_game
          status: 'placement'
        Session.write_location('game')
        @.hide_content()
        @ctrl_game.show_content()
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
    n = Utils.get_selected(@_list_maps)
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
    '#game_creation .name_game':    '_name_game'

    '#game_creation .list_armies':  '_list_armies'
    '#game_creation .list_maps':    '_list_maps'
    '#game_creation .map':          '_map'
    '#game_creation .army':         '_army'

    '#game_creation .btn_create':   '_btn_create'

  events:
    'click #game_creation .btn_create': 'create_game'

  constructor: (el, @ws, @ctrl_game) ->
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
      RMap.render(@_map, map.width, map.height, map.structure)
      @map = map
      @map.name = name_map

  load_army: (name_army) ->
    RArmy.load @ws, name_army, (army) =>
      RArmy.render(@_army, army.units)
      @army = army
      @army.name = name_army

  create_game: ->
    #Validate
    @ws.send(
      {
        cmd: 'createGame'
        name: @_name_game.val()
        nameMap: @map.name
        nameArmy: @army.name
      },
      =>
        @.hide_content()
        Session.write_location('game')
        Game.remove()
        Game.create(
          name: @_name_game.val(),
          map: @map
          army: @army
          status: 'created'
        )
        AppCtrl.update_menu(true)
        @ctrl_game.show_content()
    )

#-------- Game --------

class GameCtrl extends Spine.Controller
  elements:
    '#game': '_location'

  constructor: (el, @ws, @ctrl_about_project) ->
    super(el: el)
    @game_ctrls =
      created:    new GameCreatedCtrl(el, @ws, @, @ctrl_about_project)
      placement:  new GamePlacementCtrl(el, @ws, @, @ctrl_about_project)
      process:    new GameProcessCtrl(el, @ws, @, @ctrl_about_project)

  show_content: ->
    @_location.show()
    game_status = Game.first().status.toLowerCase()
    @game_ctrls[game_status].show_content()

  hide_content: ->
    v.hide_content() for k, v of @game_ctrls
    @_location.hide()

#-------- GameCreated --------

class GameCreatedCtrl extends Spine.Controller
  elements:
    '#game_created':                  '_location'
    '#game_created .army_panel h3':   '_name_army'
    '#game_created .map_panel h3':    '_name_map'
    '#game_created .left_side h3':    '_name_game'
    '#game_created .map':             '_map'
    '#game_created .army':            '_army'

  events:
    'click #game_created .btn_remove':      'remove_game'

  constructor: (el, @ws, @ctrl_game, @ctrl_about_project) ->
    super(el: el)

  show_content: ->
    @ws.subscribe 'startGamePlacement', =>
      Game.write_status('placement')
      Session.write_location('game')
      @.hide_content()
      @ctrl_game.show_content()

    local_game = Game.first()
    map = local_game.map
    army = local_game.army

    @_name_game.html(local_game.name)
    @_name_army.html(local_game.army.name)
    @_name_map.html(local_game.map.name)

    RMap.render(@_map, map.width, map.height, map.structure)
    RArmy.render(@_army, army.units)

    @_location.show()

  hide_content: ->
    @_location.hide()
    a = [@_map, @_army, @_name_game, @_name_army, @_name_map]
    obj.empty() for obj in a

  remove_game: ->
    @ws.send { cmd: 'destroyGame' }, =>
      @ws.unsubscribe 'startGamePlacement'

      Session.write_location('about_project')
      Game.remove()
      AppCtrl.update_menu(false)

      @ctrl_game.hide_content()
      @ctrl_about_project.show_content()


#-------- GamePlacement --------

class GamePlacementCtrl extends Spine.Controller
  elements:
    '#game_placement':              '_location'
    '#game_placement .map':         '_map'
    '#game_placement .army':        '_army'

  constructor: (el, @ws, @ctrl_about_project) ->
    super(el: el)

  show_content: ->
    @_location.show()
    @ws.send { cmd: 'getGame' }, (game) =>
      map = game.map
      structure =
        obst: map.obst
        pl1: game.state.pl1
        pl2: game.state.pl2
      RMap.render(@_map, map.width, map.height, structure)
      RArmy.render(@_army, game.army.units, 1)
    
  hide_content: ->
    @_location.hide()

#-------- GameProcess --------

class GameProcessCtrl extends Spine.Controller
  elements:
    '#game_process': '_location'

  constructor: (el, @ws, @ctrl_about_project) ->
    super(el: el)

  show_content: ->
    @_location.show()

  hide_content: ->
    @_location.hide()

#-------- AboutProjectCtrl --------

class AboutProjectCtrl extends Spine.Controller
  elements:
    '#about_project': '_location'

  constructor: (el) ->
    super(el: el)

  show_content: ->
    @_location.show()

  hide_content: ->
    @_location.hide()

#-------- App --------

class AppCtrl extends Spine.Controller
  elements:
    '#content':                 '_content'

    '#btn_about_project':       '_btn_about_project'

    '#main_menu .top_menu':     '_top_menu'
    '#main_menu .middle_menu':  '_middle_menu'

    '#profile':     '_profile'
    '#auth':        '_auth'

  events:
    'click #btn_users_online':    'nav_location'
    'click #btn_available_games': 'nav_location'
    'click #btn_maps_editor':     'nav_location'
    'click #btn_game_creation':   'nav_location'
    'click #btn_game':            'nav_location'
    'click #btn_about_project':   'nav_location'

  @update_menu: (is_in_game) ->
    f = if is_in_game then ['hide', 'show'] else ['show', 'hide']
    for s in ['available_games', 'game_creation']
      $("#btn_#{s}")[f[0]]()
    $('#btn_game')[f[1]]()

  constructor: ->
    super
    Utils.restore_model(Session, 'Session')

    @ctrls = {}
    @ctrls.about_project = new AboutProjectCtrl(@_content)

    @ws = new Websocket(
      'localhost',
      9001,
      (=>      #After opened websocket
        @auth_ctrl = new AuthCtrl(
          '#top_menu',
          @ws,
          $.proxy(@.handle_login, @),
          $.proxy(@.handle_logout, @)
        )
      ),
      $.proxy(@.handle_logout, @)
    )

  handle_login: ->
    @_auth.hide()
    @_profile.show()
    obj.show() for obj in [@_top_menu, @_middle_menu]
    @.init_ctrls()

  handle_logout: ->
    @_profile.hide()
    @_auth.show()

    @ws.unsubscribe_all()

    Session.remove()
    Session.create(location: 'about_project')
    Game.remove()

    obj.hide() for obj in [@_top_menu, @_middle_menu]
    @_btn_about_project.click()

  init_ctrls: ->
    @ctrls.game = new GameCtrl(@_content, @ws, @ctrls.about_project)
    @ctrls.game_creation = new GameCreationCtrl(@_content, @ws, @ctrls.game)

    @ctrls.users_online     = new UsersOnlineCtrl(@_content, @ws)
    @ctrls.available_games  = new AvailableGamesCtrl(@_content, @ws, @ctrls.game)
    @ctrls.maps_editor      = new MapsEditorCtrl(@_content, @ws)

    Utils.restore_model(Game, 'Game')

    s = Session.first()
    AppCtrl.update_menu(Game.first())
    if s.location
      @ctrls[s.location].show_content()
    else
      @ctrls['about_project'].show_content()
      s.location = 'about_project'
      s.save()

  nav_location: (event) ->
    ctrl = event.handleObj.selector.slice(5)
    Session.write_location(ctrl)
    v.hide_content() for k, v of @ctrls
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

  @render: (cont, units, col_count = 3) ->
    u = ({ unit: k, count: v } for k, v of units)
    Utils.compile_templ(
      '#templ_army',
      cont,
      {
        units: u
        count: u.length
        col_count: col_count
      }
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

  @get_selected: (ul_cont) ->
    obj = ul_cont.find('li.selected')
    return Utils.strip(obj.html())

  @restore_model: (model, model_name) ->
    data = $.parseJSON(sessionStorage.getItem(model_name))
    sessionStorage.removeItem(model_name)
    model.create(data[0]) if data?

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

