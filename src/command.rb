#coding: utf-8

require 'validation'
require File.join(File.dirname(__FILE__), '..', 'db', 'seeds')

#--------------------- Dynamic creation methods --------------------- 

def def_init(cl, *fields)
  cl.class_eval do 
    define_method(:initialize) do |req|
      super(req, fields)
    end
  end
end

#--------------------- Modules --------------------- 

module Utils
  def clone(obj)
    Marshal.load Marshal.dump(obj)
  end

  def h_slice(h, keys)
    h.select { |k, v| keys.include? k }
  end
end

module Database
  @@db_conn, @@db = '', ''

  module_function

  def self.set_db(db_conn, db)
    @@db_conn, @@db = db_conn, db
  end

  def exist?(coll, sel)
    @@db[coll].find(sel).count > 0
  end

  def get_user(sid)
    user = @@db['users'].find_one 'sid' => sid
    if user.nil?
      raise ResponseBadSession, 'Incorrect session id'
    end

    user
  end

  def get_by_name(db_name, name, case_sensitive = false)
    sel = case_sensitive ? name : Regexp.new(name, true)
    res = @@db[db_name].find_one 'name' => sel
    if res.nil?
      raise ResponseBadResource, 'Resource is\'t exist'
    end

    res
  end

  def get_by_id(db_name, id)
    @@db[db_name].find_one '_id' => id
  end

  def check_access(user, res)
    unless user['_id'] == res['creator']
      raise ResponseBadAccess, 'Illegal access'
    end
  end

  def cur_to_arr(coll_name, sel, field)
    arr = []
    cur = @@db[coll_name].find sel, :fields => [field]
    cur.each { |foo| arr << foo[field] }

    arr
  end
end

#--------------------- Cmd --------------------- 

class Cmd
  include Validations, Utils, Database

  MSGS = {
    :flds_num_l => 'Request has\'t enough fields for this command',
    :flds_num_g  => 'Request has extra fields for this command'
  }

  def initialize(req, fields)
    check_fields req, fields
  end

  def check_fields(req, fields)
    fields.each do |f|
      unless req.has_key? f
        raise ResponseBadCommand, MSGS[:flds_num_l]
      end
    end
    if req.size > fields.size
      raise ResponseBadCommand, MSGS[:flds_num_g]
    end
  end

  def encode(val, salt)
    Digest::SHA2.hexdigest "#{val}--#{salt}"
  end
  private :encode
end

#--------------------- Dev --------------------- 

class CmdDropDB < Cmd
  def_init self

  def handle(req)
    @@db_conn.drop_database @@db.name

    Seed.create_indexes @@db
    Seed.seed_units @@db

    [{}, {}]
  end
end

#--------------------- Auth --------------------- 

class CmdSignup < Cmd
  def_init self, 'login', 'password'

  def handle(req)
    Validator.validate @@db['users'], req, V_USER

    t = Time.now.utc
    e_passw = encode req['password'], t
    sid = encode req['login'], Time.now.utc

    id = @@db['users'].insert({
      'login' => req['login'],
      'password' => e_passw,
      'status' => :online,
      'sid' => sid,
      'created_at' => t
    })

    [
      {
        'sid' => sid,
        'login' => req['login']
      },
      {
        :all => {
          'cmd' => 'addUserOnline',
          'login' => req['login']
        }
      },
      { 'reg' => id }
    ]
  end
end

class CmdLogin < Cmd
  def_init self, 'login', 'password'

  def handle(req)
    user = @@db['users'].find_one 'login' => Regexp.new(req['login'], true)

    if user.nil?
      raise ResponseBadAction, 'Incorrect login'
    end

    e_passw = encode req['password'], user['created_at']
    unless e_passw == user['password']
      raise ResponseBadAction, 'Incorrect password'
    end

    sid = encode user['login'], Time.now.utc

    @@db['users'].update(
      { '_id' => user['_id'] },
      { '$set' => { 'status' => :online, 'sid' => sid } }
    )

    [
      {
        'sid' => sid,
        'login' => user['login']
      },
      {
        :all => {
          'cmd' => 'addUserOnline',
          'login' => user['login']
        },
      },
      { 'reg' => user['_id'] }
    ]
  end
end

class CmdLogout < Cmd
  def_init self, 'sid'

  def handle(req)
    user = get_user req['sid']

    [
      {},
      {
        :all => {
          'cmd' => 'delUserOnline',
          'login' => user['login']
        },
      },
      { 'unreg' => user['_id'] }
    ]
  end
end

#--------------------- Units --------------------- 

class CmdGetAllUnits < Cmd
  def_init self, 'sid'

  def handle(req)
    user = get_user req['sid']

    units = {}
    @@db['units'].find().each do |unit|
      units[unit['name']] = [
        unit['rank'],
        unit['move_length'],
        unit['min_count'],
        unit['max_count']
      ]
    end

    [{ 'units' => units }, {}, {}]
  end
end

#--------------------- Maps --------------------- 

module Map
  include Database

  def check_map(width, height, struct)
    #Check values
    check_value = ->(a) do
      max_val = width * height
      a.each do |val|  
        return false unless (0...max_val).include?(val)
      end
      true
    end

    #Check collisions
    check_collisions = ->(a1, a2) do
      (a1.select { |p| a2.include? p }).empty?
    end

    #Check unique values into arrays
    check_unique = ->(a) do
      h = Hash.new(0)
      a.each { |v| h[v] += 1; return false if h[v] > 1 }
      true
    end

    is_correct = struct['pl1'].size == struct['pl2'].size

    is_correct &&=
      check_value.(struct['pl1']) &&
      check_value.(struct['pl2']) &&
      check_value.(struct['obst']) &&

    is_correct &&=
      check_unique.(struct['pl1']) &&
      check_unique.(struct['pl2']) &&
      check_unique.(struct['obst'])

    is_correct &&= 
      check_collisions.(struct['pl1'], struct['pl2']) &&
      check_collisions.(struct['pl1'], struct['obst']) &&
      check_collisions.(struct['pl2'], struct['obst'])

    raise ResponseBadMap, 'Incorrect map' unless is_correct
  end

  def reflect_map!(map)
    w, h = map['width'], map['height']
    size = w * h

    struct = map['structure']
    struct['pl1'], struct['pl2'] = struct['pl2'], struct['pl1']

    reflect = ->(a) do
      a.each_index { |i| a[i] = size - a[i] - 1 }
    end

    %w[pl1 pl2 obst].each { |a| reflect.(struct[a]) }
  end
end

class CmdCreateMap < Cmd
  include Map

  def_init self, 'sid', 'name', 'width', 'height', 'structure'

  def handle(req)
    Validator.validate @@db['maps'], req, V_MAP

    check_map req['width'], req['height'], req['structure']
    
    user = get_user req['sid']

    @@db['maps'].insert(
      {
        'name' => req['name'],
        'creator' => user['_id'],
        'created_at' => Time.now.utc
      }.merge(
        h_slice(req, %w[width height structure])
      )
    )

    [{},{},{}]
  end
end

class CmdEditMap < Cmd
  include Map

  def_init self, 'sid', 'name', 'width', 'height', 'structure'

  def handle(req)
    v_map = clone V_MAP
    v_map.delete 'name'
    Validator.validate @@db['maps'], req, v_map

    check_map req['width'], req['height'], req['structure']
    
    user = get_user req['sid']
    map = get_by_name 'maps', req['name']
    check_access user, map

    @@db['maps'].update(
      { '_id' => map['_id'] },
      {
        '$set' => h_slice(req, %w[width height structure])
      }
    )

    [{},{},{}]
  end
end

class CmdDestroyMap < Cmd
  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    map = get_by_name 'maps', req['name']
    check_access user, map

    @@db['maps'].remove '_id' => map['_id']

    [{},{},{}]
  end
end

class CmdGetListMaps < Cmd
  def_init self, 'sid'

  def handle(req)
    user = get_user req['sid']
    maps = cur_to_arr 'maps', get_selector(user), 'name'

    [{ 'maps' => maps },{},{}]
  end

  def get_selector(user)
    { 'creator' => user['_id'] }
  end
  private :get_selector
end

class CmdGetListAllMaps < CmdGetListMaps
  def get_selector(user); {}; end
  private :get_selector
end

class CmdGetMapParams < Cmd
  def_init self, 'sid', 'name'

  def handle(req)
    get_user req['sid']
    map = get_by_name 'maps', req['name']

    [h_slice(map, %w[width height structure]),{},{}]
  end
end

#--------------------- Armies --------------------- 

module Army
  include Database

  ERR_MSG = 'Incorrect army'

  def check_army(units)
    raise ResponseBadArmy, ERR_MSG if units.empty?
    units.each_pair do |army_unit, count|
      u = @@db['units'].find_one 'name' => army_unit

      raise ResponseBadArmy, ERR_MSG if u.nil?

      r = u['min_count']..u['max_count']
      raise ResponseBadArmy, ERR_MSG unless r.include?(count)
    end
  end
end

class CmdCreateArmy < Cmd
  include Army

  def_init self, 'sid', 'name', 'units'

  def handle(req)
    Validator.validate @@db['armies'], req, V_ARMY

    check_army req['units']
    
    user = get_user req['sid']

    @@db['armies'].insert({
      'name' => req['name'],
      'creator' => user['_id'],
      'units' => req['units'],
      'created_at' => Time.now.utc
    })

    [{},{},{}]
  end
end

class CmdEditArmy < Cmd
  include Army

  def_init self, 'sid', 'name', 'units'

  def handle(req)
    check_army req['units']
    
    user = get_user req['sid']
    army = get_by_name 'armies', req['name']
    check_access user, army

    @@db['armies'].update(
      { '_id' => army['_id'] },
      { 
        '$set' => {
          'units' => req['units'],
        }
      }
    )

    [{},{},{}]
  end
end

class CmdDestroyArmy < Cmd
  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    army = get_by_name 'armies', req['name']
    check_access user, army

    @@db['armies'].remove '_id' => army['_id']

    [{},{},{}]
  end
end

class CmdGetListArmies < Cmd
  def_init self, 'sid'

  def handle(req)
    user = get_user req['sid']
    armies = cur_to_arr 'armies', get_selector(user), 'name'

    [{ 'armies' => armies },{},{}]
  end

  def get_selector(user)
    { 'creator' => user['_id'] }
  end
  private :get_selector
end

class CmdGetListAllArmies < CmdGetListArmies
  def get_selector(user); {}; end
  private :get_selector
end

class CmdGetArmyUnits < Cmd
  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    army = get_by_name 'armies', req['name']

    [{ 'units' => army['units'] },{},{}]
  end
end


#--------------------- Games --------------------- 

module Game
  include Database

  ERR_MSG = 'Incorrect game'

  def check_game(map, army)
    units_count = army['units'].values.reduce(:+)
    unless units_count == map['structure']['pl1'].size
      raise ResponseBadGame, ERR_MSG
    end
  end

  def check_user(user_id)
    sel = { '$or' => [
      { 'creator' => user_id },
      { 'opponent' => user_id }
    ] }
    if (exist?('games', sel))
      raise ResponseBadAction, 'User already in a game'
    end
  end
end

class CmdCreateGame < Cmd
  include Game

  def_init self, 'sid', 'name', 'nameMap', 'nameArmy'
  def handle(req)
    Validator.validate @@db['games'], req, V_GAME

    user = get_user req['sid']
    check_user user['_id']

    map = get_by_name 'maps', req['nameMap']
    army = get_by_name 'armies', req['nameArmy']

    check_game map, army

    @@db['games'].insert({
      'name' => req['name'],
      'creator' => user['_id'],
      'map' => map['_id'],
      'army' => army['_id'],
      'created_at' => Time.now.utc
    })
    
    [
      {},
      {
        :all => {
          'cmd' => 'addAvailableGame',
          'name' => req['name']
        }
      },
      {}
    ]
  end
end

class CmdGetGameParams < Cmd
  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    game = get_by_name 'games', req['name']
    map = get_by_id 'maps', game['map']
    army = get_by_id 'armies', game['army']
    
    [
      {
        'map' => h_slice(map, %w[name width height structure]),
        'army' => h_slice(army, %w[name units])
      },
      {}, {}
    ]
  end
end

class CmdJoinGame < Cmd
  include Game

  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    check_user user['_id']

    game = get_by_name 'games', req['name']
    
    unless game['opponent'].nil?
      raise ResponseBadGame, 'The game isn\'t available'
    end

    @@db['games'].update(
      { '_id' => game['_id'] },
      { '$set' => { 'opponent' => user['_id'] } }
    )
  
    [
      {},
      { 
        game['creator'] => {
          'cmd' => 'startGamePlacement'
        },
        :all => {
          'cmd' => 'delAvailableGame',
          'name' => game['name']
        }
      },
      {}
    ]
  end
end

class CmdGetGame < Cmd
  include Map

  def_init self, 'sid', 'name'

  def handle(req)
    user = get_user req['sid']
    game = get_by_name 'games', req['name']

    unless [game['creator'], game['opponent']].include?(user['_id'])
      raise ResponseBadAction, 'User isn\'t player of this game'
    end

    if game['placement'].nil?
      map = get_by_id 'maps', game['map']
      army = get_by_id 'armies', game['army']
      h_map = h_slice(map, %w[name width height structure])
      h_army = h_slice(army, %w[name units])

      reflect_map!(h_map) if game['opponent'] == user['_id']

      resp = {
        'status' => 'placement',
        'map' => h_map,
        'army' => h_army
      }
    else
      #Game is started
    end
  
    [resp, {}, {}]
  end
end

