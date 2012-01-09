#coding: utf-8

class ClContainer
  @@db = nil
  @@db_conn = nil
  @@container_ws = {}
  @@container_id = {}

  def self.set_db(db_conn, db)
    @@db_conn, @@db = db_conn, db
  end

  def self.reg_client(ws, user_id)
    @@container_ws[ws] = user_id 
    @@container_id[user_id] = ws
  end

  def self.unreg_client_by_id(user_id)
    #@@db['users'].update(
    #  { '_id' => user_id },
    #  { '$set' => { 'status' => :offline } }
    #)
    @@container_ws.delete @@container_id[user_id]
    @@container_id.delete user_id
  end

  def self.unreg_client_by_ws(ws)
    return unless @@container_ws.has_key?(ws)
    user = @@db['users'].find_one '_id' => @@container_ws[ws]
    unreg_client_by_id user['_id']
    #Так же необходимо будет уведомить всех пользователей об уходе
  end

  def self.get_ws_by_id(user_id)
    @@container_id[user_id]
  end

  def self.get_id_by_ws(ws)
    @@container_ws[ws]
  end

  def self.get_all_ws
    @@container_ws.keys
  end

  def self.get_all_id
    @@container_id.keys
  end

end

