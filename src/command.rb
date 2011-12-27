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

#--------------------- Cmd --------------------- 

class Cmd
  include VALIDATIONS

  MSGS = {
    :flds_num_l => 'Request has\'t enough fields for this command',
    :flds_num_g  => 'Request has extra fields for this command'
  }

  def self.set_db(db_conn, db)
    @@db_conn, @@db = db_conn, db
  end

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

  def exist?(coll, sel)
    @@db[coll].count(sel) > 0
  end

  def encode(val, salt)
    Digest::SHA2.hexdigest "#{val}--#{salt}"
  end
  private :encode

  def clone(obj)
    Marshal.load Marshal.dump(obj)
  end
  private :clone

  def get_user(sid)
    user = @@db['users'].find_one 'sid' => sid
    if user.nil?
      raise ResponseBadSession, 'Incorrect session id'
    end

    user
  end
  private :get_user

  def get_by_name(db_name, name, case_sensitive = false)
    sel = case_sensitive ? Regexp.new(name, true) : name
    res = @@db[db_name].find_one 'name' => sel
    if res.nil?
      raise ResponseBadResource, 'Resource is\'t exist'
    end

    res
  end
  private :get_by_name

  def check_access(user, res)
    unless user['_id'] == res['creator']
      raise ResponseBadAccess, 'Illegal access'
    end
  end
  private :check_access

  def cur_to_arr(db_name, sel, field)
    arr = []
    cur = @@db[db_name].find sel, :fields => [field]
    cur.each { |foo| arr << foo[field] }

    arr
  end
  private :cur_to_arr
end

#--------------------- Dev --------------------- 
#
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
      { 'sid' => sid },
      { 'cmd' => 'addUserOnline', 'login' => req['login'] },
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
      { 'sid' => sid },
      { 'cmd' => 'addUserOnline', 'login' => user['login'] },
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
      { 'cmd' => 'delUserOnline', 'login' => user['login'] },
      { 'unreg' => user['_id'] }
    ]
  end
end

#--------------------- Maps --------------------- 

module Map
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
end

class CmdCreateMap < Cmd
  include Map

  def_init self, 'sid', 'name', 'width', 'height', 'structure'

  def handle(req)
    Validator.validate @@db['maps'], req, V_MAP

    check_map req['width'], req['height'], req['structure']
    
    user = get_user req['sid']

    @@db['maps'].insert({
      'name' => req['name'],
      'creator' => user['_id'],
      'width' => req['width'],
      'height' => req['height'],
      'structure' => req['structure'],
      'created_at' => Time.now.utc
    })

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
      { '$set' => { 
        'width' => req['width'], 
        'height' => req['height'], 
        'structure' => req['structure'], 
      } }
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

    [{
      'width' => map['width'],
      'height' => map['height'],
      'structure' => map['structure'],
    },{},{}]
  end
end

#--------------------- Armies --------------------- 

module Army
  ERR_MSG = 'Incorrect army'

  def check_army(coll_units, units)
    raise ResponseBadArmy, ERR_MSG if units.empty?
    units.each_pair do |army_unit, count|
      u = coll_units.find_one 'name' => army_unit

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

    check_army @@db['units'], req['units']
    
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

