$(document).ready(->
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

class Unit extends Spine.Model
  @configure 'Unit', 'name', 'count', 'move_length'

  @init: (units) ->
    @.deleteAll()
    for k, v of units
      @.create(
        name: k
        count: v.count
        move_length: v.moveLength
      )

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

  login: (event) ->
    event.preventDefault()
    @.show_modal('login')

  signup: (event) ->
    event.preventDefault()
    @.show_modal('signup')

  logout: (event) ->
    event.preventDefault()
    @ws.send(
      { cmd: 'logout' },
      $.proxy(@handler_logout, @)
    )

  show_modal: (cmd) ->
    new ModalAuth(
      header:     Utils.capitalize(cmd)
      handle_ok:  (login, password) =>
        @.auth(cmd, login, password)
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
    @_location.templater(
      '#templ_resources',
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
    Utils.empty(@_map, @_army, @_name_army, @_name_map)

  render_list: ->
    @_list_games.templater(
      '#templ_list',
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
    unless @_list_games.find('li.selected').size()
      Notifications.add(
        type: 'error'
        text: "Game isn't selected"
      )
      return
    name_game = Utils.get_selected(@_list_games)
    @ws.send(
      {
        cmd: 'joinGame'
        name: name_game
      },
      =>
        g = AvailableGame.findByAttribute(name: name_game)
        AvailableGame.destroy(g.id)

        Game.remove()
        Game.create
          name: name_game
          status: 'placement'

        Session.write_location('game')
        AppCtrl.update_menu(true)
        @.hide_content()
        @ctrl_game.show_content()
    )

#-------- Maps editor --------

class MapsEditorCtrl extends Spine.Controller
  elements:
    '#maps_editor':                 '_location'

    '#maps_editor .tools':          '_tools'

    '#maps_editor .list_maps':      '_list_maps'
    '#maps_editor .map':            '_map'
    '#maps_editor #name_map':       '_name_map'
    '#maps_editor #width_map':      '_width_map'
    '#maps_editor #height_map':     '_height_map'

    '#maps_editor .btn_del':        '_btn_del'
    '#maps_editor .btn_save':       '_btn_save'
    '#maps_editor #btn_clean_map':  '_btn_clean'
    '#maps_editor #btn_gen_map':    '_btn_generate'

    '#modal_map_del':               '_modal_del'

  events:
    'click #maps_editor .btn_new':        'add_map'
    'click #maps_editor .btn_del':        'delete_map'
    'click #maps_editor .btn_save':       'save_map'

    'click #btn_gen_map':                 'generate_map'
    'click #btn_clean_map':               'clean_map'

    'click #maps_editor .tools li':       'select_tool'
    'click #maps_editor .map .map_cell':  'set_map_cell'

  constructor: (el, @ws) ->
    super(el: el)
    for el in [@_width_map, @_height_map]
      el.force_num_only($.proxy(@.generate_map, @))

  show_content: ->
    @_location.show()
    @.flush()
    Map.deleteAll()
    @ws.send { 'cmd': 'getListMaps' }, (req) =>
        for m in req.maps
          Map.create(name: m)
        @.render_list()

  hide_content: ->
    @.flush()
    @_list_maps.empty()
    @_location.hide()

  flush: ->
    @_map.empty()
    for el in ['name', 'width', 'height']
      @["_#{el}_map"].val('')
    
    Utils.hide(
      @_name_map,
      @_width_map,
      @_height_map,
      @_btn_clean
      @_btn_generate
      @_tools
    )
    Utils.disable(@_btn_del, @_btn_save)
    Utils.unselect(@_list_maps, @_tools)

  render_list: (map_selected) ->
    @_list_maps.templater(
      '#templ_list',
      { list: Map.all(), el_selected: map_selected }
    )
    @_list_maps.find('li').on 'click', (event) =>
      obj = $(event.target)
      @is_new = false
      Utils.select_li(obj)
      @.load_map(Utils.strip(obj.html()))

  load_map: (name_map) ->
    RMap.load @ws, name_map, (map) =>
      for el in ['width', 'height']
        @["_#{el}_map"].show().val(map[el])
      @_name_map.show().val(name_map)
      @.render_map(map.width, map.height, map.structure)

      Utils.enable(@_btn_del, @_btn_save)
      Utils.disable(@_name_map)
      @_btn_generate.show()

  render_map: (width, height, structure) ->
    RMap.render(@_map, width, height, structure)

    @_tools.show()
    Utils.select_li(@_tools.find('li:first'))

    Utils.enable(@_btn_save)
    @_btn_clean.show()

    @_last_width = width

  add_map: ->
    @_map.empty()

    Utils.show(
      @_name_map
      @_width_map
      @_height_map
      @_btn_generate
    )
    Utils.hide(@_tools, @_btn_clean)
    Utils.disable(@_btn_del, @_btn_save)
    Utils.enable(@_name_map)
    Utils.unselect(@_list_maps)

    for obj in [@_name_map, @_width_map, @_height_map]
      obj.val('')
    @is_new = true

  delete_map: ->
    n = Utils.get_selected(@_list_maps)
    new ModalYesNo(
      header:     'Deletion of the map' 
      text:       "Are you want to delete '#{n}' map"
      handle_ok:  =>
        @ws.send { cmd: 'destroyMap', name: n }, =>
          Map.destroy(Map.findByAttribute('name', n).id)
          @.render_list()
          @.flush()

          Notifications.add(
            type: 'success'
            text: 'Map has been deleted'
          )
    )

  validate_map: ->
    res = true

    pl1_count = @_map.find('.pl1').size()
    pl2_count = @_map.find('.pl2').size()
    unless pl1_count == pl2_count
      text = 'Number of cells for two players must match'
      res = false
    unless pl1_count > 1
      text = 'The number of cells for a player to be at least 2'
      res = false
    
    Notifications.add(type: 'error', text: text) unless res
    return res

  save_map: ->
    #Validate inputs
    return unless @.validate_map()

    make_a = (cl) =>
      (for el in @_map.find(".map_cell.#{cl}")
        parseInt($(el).attr('id').slice(5)))

    req =
      name: @_name_map.val()
      width: parseInt(@_width_map.val())
      height: parseInt(@_height_map.val())
      structure:
        pl1:  make_a('pl1')
        pl2:  make_a('pl2')
        obst: make_a('obst')

    if @is_new
      req.cmd = 'createMap'
      @ws.send req, =>
        Map.create(name: @_name_map.val())
        @.render_list(@_name_map.val())
        Utils.enable(@_btn_del)
        Utils.disable(@_name_map)
        @is_new = false

        Notifications.add(
          type: 'success'
          text: 'Map has been created'
        )

      return

    new ModalYesNo(
      header:     'Saving of the map' 
      text:       "Are you want to save '#{req.name}' map"
      handle_ok:  =>
        req['cmd'] = 'editMap'
        @ws.send req, =>
          Notifications.add(
            type: 'success'
            text: 'Map has been saved'
          )
    )

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

class ArmiesEditorCtrl extends Spine.Controller
  elements:
    '#armies_editor':                   '_location'
    
    '#armies_editor .list_armies':      '_list_armies'
    '#armies_editor .army':             '_army'
    '#armies_editor #name_army':        '_name_army'
    
    '#armies_editor .btn_del':          '_btn_del'
    '#armies_editor .btn_save':         '_btn_save'
    '#armies_editor #btn_clean_army':   '_btn_clean_army'

  events:
    'click #armies_editor .btn_new':        'add_army'
    'click #armies_editor .btn_del':        'delete_army'
    'click #armies_editor .btn_save':       'save_army'
    'click #armies_editor #btn_clean_army': 'clean_army'

  constructor: (el, @ws) ->
    super(el: el)

  show_content: ->
    @_location.show()
    @.flush()
    Army.deleteAll()
    @ws.send { 'cmd': 'getListArmies' }, (req) =>
        for a in req.armies
          Army.create(name: a)
        @.render_list()

  hide_content: ->
    @.flush()
    @_list_armies.empty()
    @_location.hide()

  flush: ->
    @_army.empty()
    @_name_army.val('')

    Utils.hide(@_name_army, @_btn_clean_army)
    Utils.disable(@_btn_del, @_btn_save)
    Utils.unselect(@_list_armies)

  render_list: (army_selected) ->
    @_list_armies.templater(
      '#templ_list',
      { list: Army.all(), el_selected: army_selected }
    )
    @_list_armies.find('li').on 'click', (event) =>
      obj = $(event.target)
      @is_new = false
      Utils.select_li(obj)
      @.load_army(Utils.strip(obj.html()))
  
  load_army: (name_army) ->
    RArmy.load @ws, name_army, (army) =>
      Unit.init(army.units)

      @_name_army.val(name_army)
      RArmy.render_edt(@_army, army.units)

      Utils.show(@_name_army, @_btn_clean_army)
      Utils.enable(@_btn_save, @_btn_del)
      Utils.disable(@_name_army)

  add_army: ->
    @ws.send { cmd: 'getAllUnits' }, (data) =>
      Unit.init(data.units)

      units = data.units
      for k, v of units
        units[k].count = v.minCount
      RArmy.render_edt(@_army, units)

      Utils.show(@_name_army, @_btn_clean_army)
      Utils.enable(@_btn_save, @_name_army)
      Utils.disable(@_btn_del)
      Utils.unselect(@_list_armies)

      @_name_army.val('')
      @is_new = true

  delete_army: ->
    n = Utils.get_selected(@_list_armies)
    new ModalYesNo(
      header:     'Deletion of the army' 
      text:       "Are you want to delete '#{n}' army"
      handle_ok:  =>
        @ws.send { cmd: 'destroyArmy', name: n }, =>
          Army.destroy(Army.findByAttribute('name', n).id)
          @.render_list()
          @.flush()

          Notifications.add(
            type: 'success'
            text: 'Army has been deleted'
          )
    )
  
  validate_army: ->
    res = true

    army = {}
    common_move_lenght = 0
    @_army.find('li').each (i, el) ->
      obj = $(el)
      unit_name = Utils.strip(obj.find('.unit_name').html())
      count = parseInt(obj.find('.unit_count').val())
      army[unit_name] = count
      if count
        u = Unit.findByAttribute('name', unit_name)
        common_move_lenght += u.move_length

    console.log(common_move_lenght)
    unless common_move_lenght
      text = 'Must be at least one active unit'
      res = false
    if army['Bomb'] && !army['Miner']
      text = 'If there is a bomb, there must be a miner'
      res = false
      
    Notifications.add(type: 'error', text: text) unless res

    return res

  save_army: ->
    #Validate name of the army
    return unless @.validate_army()

    req =
      name: @_name_army.val()
      units: {}

    @_army.find('.unit_count').each (i, el) =>
      obj_count = $(el)
      obj_name = obj_count.parent().find('.unit_name')
      count = parseInt(obj_count.val())
      name = Utils.strip(obj_name.html())
      req.units[name] = count if count

    if @is_new
      req.cmd = 'createArmy'
      @ws.send req, =>
        Army.create(name: req.name)
        @.render_list(@_name_army.val())
        Utils.enable(@_btn_del)
        @is_new = false
        Utils.disable(@_name_army)

        Notifications.add(
          type: 'success'
          text: 'Army has been created'
        )

      return

    new ModalYesNo(
      header:     'Saving of the army' 
      text:       "Are you want to save '#{req.name}' army"
      handle_ok:  =>
        req.cmd = 'editArmy'
        @ws.send req, =>
          Notifications.add(
            type: 'success'
            text: 'Army has been saved'
          )
    )

  clean_army: ->
    @_army.find('.unit_count').each (i, el) =>
      obj = $(el)
      Utils.unselect(obj)
      obj.find('option:first-child').attr('selected', 'selected')

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
    Utils.empty(@_map, @_list_armies, @_list_maps, @_army, @_map)
    @_name_game.val('')
    @_location.hide()

  load_list: (res, model, cont, handler) ->
    model.deleteAll()
    @ws.send { 'cmd': "getListAll#{Utils.capitalize(res)}" }, (req) =>
      model.create(name: el) for el in req[res]

      cont.templater(
        '#templ_list',
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
      units = {}
      for k, v of army.units
        units[k] = v.count
      RArmy.render(@_army, units)
      @army = { units: units }
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
        Session.write_location('game')
        Game.remove()
        Game.create(
          name: @_name_game.val(),
          map: @map
          army: @army
          status: 'created'
        )
        AppCtrl.update_menu(true)
        @.hide_content()
        @ctrl_game.show_content()
    )

#-------- Game --------

class GameCtrl extends Spine.Controller
  elements:
    '#game': '_location'

  constructor: (el, @ws, @ctrl_about_project) ->
    super(el: el)
    @game_ctrls =
      created:    new GameCreatedCtrl(el, @ws, @)
      placement:  new GamePlacementCtrl(el, @ws, @)
      process:    new GameProcessCtrl(el, @ws, @)

  show_content: ->
    @_location.show()
    game_status = Game.first().status.toLowerCase()
    @game_ctrls[game_status].show_content()

  hide_content: ->
    v.hide_content() for k, v of @game_ctrls
    @_location.hide()

  exit_game: ->
    Session.write_location('about_project')
    Game.remove()
    AppCtrl.update_menu(false)

    @.hide_content()
    @ctrl_about_project.show_content()

  end_game: (is_win) ->
    new ModalEndGame(
      is_win:     is_win
      handle_ok:  =>
        @.exit_game() 
    )

  leave_game: ->
    new ModalYesNo(
      header:     'Leaving' 
      text:       'Are you want to leave the game'
      handle_ok:  =>
        @ws.send { cmd: 'leaveGame' }, =>
          @.end_game(false)
    )

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

  constructor: (el, @ws, @ctrl_game) ->
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
    Utils.empty(@_map, @_army, @_name_game, @_name_army, @_name_map)

  remove_game: ->
    new ModalYesNo(
      header:     'Removing' 
      text:       'Are you want to remove the game'
      handle_ok:  =>
        @ws.send { cmd: 'destroyGame' }, =>
          @ctrl_game.exit_game()
    )

#-------- GamePlacement --------

class GamePlacementCtrl extends Spine.Controller
  elements:
    '#game_placement':                '_location'

    '#game_placement .map':           '_map'
    '#game_placement .army':          '_army'
    '#game_placement h3':             '_game_name'

    '#game_placement .btn_ready':     '_btn_ready'
    '#game_placement .btn_clean':     '_btn_clean'

    '#game_placement .game_tactics':  '_game_tactics'

  events:
    'click #game_placement .map_cell':          'set_map_cell'
    'dblclick #game_placement .map_cell':       'clean_map_cell'
    'click #game_placement .btn_leave_game':    'leave_game'
    'click #game_placement .btn_ready':         'ready'
    'click #game_placement .btn_clean':         'clean'

  constructor: (el, @ws, @ctrl_game) ->
    super(el: el)

  show_content: ->
    @ws.subscribe 'readyOpponent', =>
      Notifications.add(
        type: 'warning'
        text: 'Opponent ready'
      )

    @ws.subscribe 'endGame', =>
      @ctrl_game.end_game(true)

    @ws.subscribe('startGame', $.proxy(@.go_to_process, @))

    @_location.show()
    @.load_game()

  hide_content: ->
    @_location.hide()
    Utils.empty(@_army, @_map)

  go_to_process: ->
    Game.write_status('process')
    Session.write_location('game')
    @.hide_content()
    @ctrl_game.show_content()

  load_game: ->
    @ws.send { cmd: 'getGame' }, (game) =>
      map = game.map
      structure =
        obst: map.obst
        pl1: game.state.pl1
        pl2: game.state.pl2
      @.render_map(map.width, map.height, structure)
      @.render_army(game.army.units)
      @_game_name.html(game.game_name)

      @ws.send { cmd: 'getGameTactics' }, (data) =>
        @.render_game_tactics(data.tactics)

      unless _.isArray(game.state.pl1)  #If already placed
        Utils.disable(@_btn_ready, @_btn_clean, @_game_tactics)
        @_army.find('.unit_count').html(0)
        @is_disabled = true

  render_map: (width, height, structure) ->
    RMap.render(@_map, width, height, structure)
    
  render_army: (units) ->
    RArmy.render(@_army, units, 1)
    @_army.find('li:first-child').addClass('selected')
    @_army.find('li').on 'click', ->
      Utils.select_li($(@))

  render_game_tactics: (tactics) ->
    @_game_tactics.templater(
      '#templ_game_tactics',
      { tactics: tactics }
    )
    @_game_tactics.on 'click', (event) =>
      tactic = tactics[@_game_tactics.val()]
      for k, v of tactic
        @_map.find("#cell_#{k}")
          .attr('class', "map_cell pl1 img_unit_#{v}")
          .attr('title', v)

      @_army.find('.unit_count').html(0)
      
  restore_prev_unit: (obj_cell) ->
    a_cl = ['pl1', 'map_cell']
    for cl in a_cl
      obj_cell.removeClass(cl)
    unless (cl = obj_cell.attr('class')) == ''
      prev = @_army.find(".#{cl}").parent().find('.unit_count')
      prev.html(parseInt(prev.html()) + 1)
      obj_cell.attr('class', '')
    for cl in a_cl
      obj_cell.addClass(cl)

  set_map_cell: (event) ->
    return if @is_disabled

    obj_cell = $(event.target)
    return unless obj_cell.hasClass('pl1')

    obj_li = @_army.find('li.selected')
    obj_unit_count = obj_li.find('.unit_count')
    unit_count = parseInt(obj_unit_count.html())
    return unless unit_count

    unit_cl = obj_li.find('span:first-child').attr('class')

    @.restore_prev_unit(obj_cell)

    obj_cell.addClass(unit_cl)
    obj_unit_count.html(parseInt(obj_unit_count.html()) - 1)
    obj_cell.attr('title', obj_li.find('.unit_name').html())

  clean_map_cell: (event) ->
    return if @is_disabled

    obj_cell = $(event.target)
    return unless obj_cell.hasClass('pl1')
    @.restore_prev_unit(obj_cell)
    obj_cell.attr('title', '')

  ready: ->
    placement = {}
    @_map.find('.map_cell.pl1').each (i, el) =>
      obj = $(el)
      a_cl = ['pl1', 'map_cell']

      for cl in a_cl
        obj.removeClass(cl)
      id = parseInt(obj.attr('id').slice(5))  #cell_<Id>
      unit = obj.attr('class').slice(9)       #img_unit_<Name>
      placement[id] = unit
      for cl in a_cl
        obj.addClass(cl)

    for k, v of placement
      if v == ''
        Notifications.add(
          type: 'error'
          text: 'Not all units placed'
        )
        return

    @ws.send(
      {
        cmd: 'setPlacement'
        placement: placement
      },
      (data) =>
        @is_disabled = true
        Utils.disable(@_btn_ready, @_btn_clean, @_game_tactics)
        @.go_to_process() if data.isGameStarted
    )

  clean: ->
    $('.map_cell.pl1').each (i, el) =>
      obj_cell = $(el)
      @.restore_prev_unit(obj_cell)
      obj_cell.attr('title', '')

  leave_game: ->
    @ctrl_game.leave_game()

#-------- GameProcess --------

class GameProcessCtrl extends Spine.Controller
  elements:
    '#game_process':                  '_location'
    '#game_process .map':             '_map'
    '#game_process .left_side h3':    '_game_name'
    '#game_process .turn_display':    '_turn_display'

  events:
    'click #game_process .map_cell.pl1':    'take_unit'
    'click #game_process .map_cell':        'make_move'
    'click #game_process .btn_leave_game':  'leave_game'

  constructor: (el, @ws, @ctrl_game) ->
    super(el: el)

  show_content: ->
    @ws.subscribe 'endGame', =>
      @ctrl_game.end_game(true)

    @ws.subscribe('opponentMakeMove', $.proxy(@.opponent_move, @))

    @.get_game()
    @_location.show()

  get_game: ->
    @ws.send { cmd: 'getGame' }, (game) =>
      map = game.map
      structure =
        obst: map.obst
        pl1: game.state.pl1
        pl2: game.state.pl2
      @.render_map(map.width, map.height, structure)
      @_game_name.html(game.game_name)
      @.update_turn(game.isTurn)

  hide_content: ->
    @_location.hide()
    @_map.empty()

  render_map: (width, height, structure) ->
    RMap.render(@_map, width, height, structure)
  
  opponent_move: (move) ->
    @.update_turn(true)

    pos_from = move.posFrom
    pos_to = move.posTo
    @_map.find("#cell_#{pos_from}").removeClass('pl2')
    cell_to = @_map.find("#cell_#{pos_to}")

    unless move.duel
      cell_to.addClass('pl2')
      return 

    d = move.duel
    new ModalDuel(
      attacker:   d.attacker
      protector:  d.protector
      result:     d.result
      handle_ok:  =>
        if d.result == 'loss'
          cell_to
            .attr('class', 'map_cell pl2')
            .attr('title', '')

        if d.result == 'draw'
          cell_to
            .attr('class', 'map_cell')
            .attr('title', '')

        if move.isEnd
          @ctrl_game.end_game(false)
    )

  take_unit: (event) -> 
    obj_cell = $(event.target)
    if obj_cell.hasClass('selected')
      obj_cell.removeClass('selected')
    else
      Utils.unselect(@_map)
      obj_cell.addClass('selected')

  make_move: (event) ->
    obj_cell = $(event.target)
    if obj_cell.hasClass('pl1') || obj_cell.hasClass('obst')
      return

    cell_from = @_map.find('.selected')
    return unless cell_from.size()

    pos_from = parseInt(cell_from.attr('id').slice(5))
    pos_to = parseInt(obj_cell.attr('id').slice(5))

    handle_move = (move) ->
      @.update_turn(false)

      cell_from.removeClass('map_cell pl1 selected')
      cl_from = cell_from.attr('class')
      cell_from.attr('class', 'map_cell')
      unit_name = cell_from.attr('title')
      cell_from.attr('title', '')

      unless move.duel
        obj_cell
          .addClass("pl1 #{cl_from}")
          .attr('title', unit_name)
        return

      d = move.duel
      new ModalDuel(
        attacker:   d.attacker
        protector:  d.protector
        result:     d.result
        handle_ok:  =>
          if d.result == 'win'
            obj_cell
              .removeClass('pl2')
              .addClass("pl1 #{cl_from}")
              .attr('title', unit_name)

          if d.result == 'draw'
            obj_cell.removeClass('pl2')

          if move.isEnd
           @ctrl_game.end_game(true)
      )

    @ws.send(
      {
        cmd: 'makeMove'
        posFrom: pos_from
        posTo: pos_to
      },
      $.proxy(handle_move, @)
    )

  leave_game: ->
    @ctrl_game.leave_game()

  update_turn: (@is_turn) ->
    pl = if @is_turn then 'You' else 'Opponent'
    @_turn_display.html("Turn: #{pl}")

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
    'click #btn_armies_editor':   'nav_location'
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
    Utils.show(@_top_menu, @_middle_menu)
    @.init_ctrls()

  handle_logout: ->
    @ws.unsubscribe_all()

    Session.remove()
    Session.create(location: 'about_project')
    Game.remove()

    @_profile.hide()
    @_auth.show()
    Utils.hide(@_top_menu, @_middle_menu)
    @_btn_about_project.click()

  init_ctrls: ->
    @ctrls.game = new GameCtrl(@_content, @ws, @ctrls.about_project)
    @ctrls.game_creation = new GameCreationCtrl(@_content, @ws, @ctrls.game)

    @ctrls.users_online     = new UsersOnlineCtrl(@_content, @ws)
    @ctrls.available_games  = new AvailableGamesCtrl(@_content, @ws, @ctrls.game)
    @ctrls.maps_editor      = new MapsEditorCtrl(@_content, @ws)
    @ctrls.armies_editor    = new ArmiesEditorCtrl(@_content, @ws)

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
    for k, v of @ctrls
      v.hide_content()
    @ctrls[ctrl].show_content()

#------------- Notifications -------------

class Notifications
  FADE_DELAY: 500
  HIDE_DELAY: 5000

  @counter: 0

  @add: (opts) ->
    list = $('#notifications ul')

    list.append('<li>')
    list
      .find('li:last-child')
      .attr('id', "notif_#{@counter}")
    
    obj_notif = $("#notif_#{@counter}")
    obj_notif.hide()
    @counter += 1

    obj_notif.templater(
      '#templ_notification',
      opts
    )

    obj_notif.fadeIn(Notifications::FADE_DELAY);

    obj_notif.find('.close').on 'click', (event) =>
      event.preventDefault()
      obj_notif.fadeOut Notifications::FADE_DELAY, =>
        obj_notif.remove()

    hide_notif = =>
      obj_notif.find('.close').click()
    window.setTimeout(
      hide_notif,
      Notifications::HIDE_DELAY
    )



#------------- Resources -------------

class RMap
  @cell_classes = ['pl1', 'pl2', 'obst']

  @load: (@ws, name_map, handler) ->
    @ws.send(
      { cmd: 'getMapParams', name: name_map },
      handler
    )

  @render: (cont, width, height, structure) ->
    cont.templater(
      '#templ_map',
      { width: width, height: height  }
    )
    if structure?
      for cl in @.cell_classes
        if _.isArray(structure[cl])
          for i in structure[cl]
            $("#cell_#{i}").addClass(cl)
        else
          for p, u of structure[cl]
            $("#cell_#{p}")
              .addClass("#{cl} img_unit_#{u}")
              .attr('title', u)

class RArmy
  @load: (@ws, name_army, handler) ->
    @ws.send(
      { cmd: 'getArmyUnits', name: name_army },
      handler
    )

  @render: (cont, units, col_count = 3) ->
    u = ({ name: k, count: v.count } for k, v of units)
    cont.templater(
      "#templ_army",
      {
        units: u
        count: u.length
        col_count: col_count
      }
    )

  @render_edt: (cont, units, col_count = 3) ->
    u = (
      for k, v of units
        {
          name: k
          count: v.count
          min_count: v.minCount
          max_count: v.maxCount
        }
    )
    cont.templater(
      "#templ_edt_army",
      {
        units: u
        count: u.length
        col_count: col_count
      }
    )

#------------- Utils -------------

class Utils
  @apply_func: (f, arr) ->
    for obj in _.flatten(arr)
      obj[f]()

  @capitalize: (str) ->
    str.slice(0, 1).toUpperCase() + str.slice(1)

  @strip: (str) ->
    str.replace(/^\s+|\s+$/g, '')

  @select_li: (obj_li) ->
    Utils.unselect(obj_li.parent())
    obj_li.addClass('selected')

  @get_selected: (ul_cont) ->
    obj = ul_cont.find('li.selected')
    return Utils.strip(obj.html())

  @restore_model: (model, model_name) ->
    data = $.parseJSON(sessionStorage.getItem(model_name))
    sessionStorage.removeItem(model_name)
    model.create(data[0]) if data?

  @disable: (args...) ->
    for obj in _.flatten(args)
      obj.attr('disabled', 'disabled')

  @enable: (args...) ->
    for obj in _.flatten(args)
      obj.removeAttr('disabled')
    
  @hide: (args...) ->
    Utils.apply_func('hide', args)

  @show: (args...) ->
    Utils.apply_func('show', args)

  @empty: (args...) ->
    Utils.apply_func('empty', args)

  @unselect: (args...) ->
    for list in _.flatten(args)
      list.find('li,.selected').removeClass('selected')

#------------- Modals -------------

class Modal
  constructor: (modal_id, params) ->
    template = $("#templ_#{modal_id}").html()
    compiled = _.template(template)
    $('body').append(compiled(params))

    @modal = $("##{modal_id}")

    @modal.on 'hidden', ->
      $(@).remove()

    @modal.modal
      backdrop: true
      keyboard: true
      show:     true

class ModalAuth extends Modal
  constructor: (opts) ->
    super(
      'modal_auth',
      { header: opts.header }
    )

    @modal.find('.cancel').on 'click', =>
      @modal.modal('hide')

    @modal.find('.ok').on 'click', =>
      opts.handle_ok(
        @modal.find('input.login').val(),
        @modal.find('input.password').val(),
      )
      @modal.modal('hide')

class ModalYesNo extends Modal
  constructor: (opts) ->
    super(
      'modal_yes_no',
      { header: opts.header, text: opts.text }
    )
    
    @modal.find('.no').on 'click', =>
      @modal.modal('hide')

    @modal.find('.yes').on 'click', =>
      opts.handle_ok()
      @modal.modal('hide')

class ModalDuel extends Modal
  constructor: (opts) ->
    super(
      'modal_duel',
      {
        attacker:   opts.attacker
        protector:  opts.protector
        result:     opts.result.toUpperCase()
      }
    )

    set_unit = (place, unit) ->
      c = place.find('.img_unit')
      c.attr('class', "#{c.attr('class')}_#{unit}")

    set_unit(@modal.find('.attacker_place'), opts.attacker)
    set_unit(@modal.find('.protector_place'), opts.protector)
    
    @modal.find('.ok').on 'click', =>
      opts.handle_ok()
      @modal.modal('hide')

class ModalYesNo extends Modal
  constructor: (opts) ->
    super(
      'modal_yes_no',
      { header: opts.header, text: opts.text }
    )
    
    @modal.find('.no').on 'click', =>
      @modal.modal('hide')

    @modal.find('.yes').on 'click', =>
      opts.handle_ok()
      @modal.modal('hide')

class ModalEndGame extends Modal
  constructor: (opts) ->
    msg =
      if opts.is_win
        'You have won the game'
      else
        'You have lossed the game'
    super('modal_end_game', { msg: msg })
    
    @modal.find('.ok').on 'click', =>
      opts.handle_ok()
      @modal.modal('hide')

#------------- jQuery functions -------------

jQuery.fn.templater = (sel_templ, options) ->
  templ = $(sel_templ).html()
  compiled = _.template(templ)
  this.empty().append(compiled(options))

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
