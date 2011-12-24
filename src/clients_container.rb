#coding: utf-8

class ClContainer
  @@db = nil
  @@db_conn = nil
  @@container = {}
  @@_container = {}

  def self.set_db(db_conn, db)
    @@db_conn, @@db = db_conn, db
  end

  def self.reg_client(ws, user_id)
    @@container[ws] = user_id 
    @@_container[user_id] = ws
  end

  def self.unreg_client_by_id(user_id)
    @@db['users'].update(
      { '_id' => user_id },
      { '$set' => { 'status' => :offline } }
    )
    @@container.delete @@_container[user_id]
    @@_container.delete user_id
  end

  def self.unreg_client(ws)
    return unless @@container.has_key?(ws)
    user = @@db['users'].find_one '_id' => @@container[ws]
    unreg_client_by_id user['_id']
    #Так же необходимо будет уведомить всех пользователей об уходе
  end

  def self.get_all_websockets
    @@container
  end
end

