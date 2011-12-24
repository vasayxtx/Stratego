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

    encode = ->(val) do
      Digest::SHA2.hexdigest "#{val}--#{Time.now.utc}"
    end

    e_passw = encode.(req['password'])
    sid = encode.(e_passw)
    @@db['users'].insert({
      'login' => req['login'],
      'password' => e_passw,
      'status' => :online,
      'sid' => sid,
      'created_at' => Time.now.utc
    })

    [
      { 'sid' => sid },
      {}
    ]
  end
end


