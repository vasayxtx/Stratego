#coding: utf-8

require 'validation'

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
      raise ResponseBadCommand, MSGS[:flds_num_l] unless req.has_key? f
    end
    raise ResponseBadCommand, MSGS[:flds_num_g] if req.size > fields.size 
  end

  def exist?(coll, sel)
    @@db[coll].count(sel) > 0
  end

  def encode(val, salt)
    Digest::SHA2.hexdigest "#{val}--#{salt}"
  end
  private :encode
end


#--------------------- Dev --------------------- 
#
class CmdDropDB < Cmd
  def_init self

  def handle(req)
    @@db_conn.drop_database @@db.name
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
      { 'addUserOnline' => req['login'] },
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
      { 'addUserOnline' => user['login'] },
      { 'reg' => user['_id'] }
    ]
  end
end

class CmdLogout < Cmd
  def_init self, 'sid'

  def handle(req)
    user = @@db['users'].find_one 'sid' => req['sid']

    if user.nil?
      raise ResponseBadAction, 'Incorrect session id'
    end

    [
      {},
      { 'delUserOnline' => user['login'] },
      { 'unreg' => user['_id'] }
    ]
  end
end

