#coding: utf-8

require File.join(File.dirname(__FILE__), 'generator')

class Seed
  @@gen = Generator.new

  ADMIN = ['Admin', 'password']

  def self.seed_all(db)
    Seed.seed_users db
    Seed.seed_messages db
    Seed.seed_units db
    Seed.seed_maps db
    Seed.seed_armies db
  end

  def self.create_indexes(db)
    db['users'].create_index 'sid', :unique => true
    db['users'].create_index 'login', :unique => true

    db['messages'].create_index 'creator'

    db['units'].create_index 'name', :unique => true
    db['units'].create_index 'rank', :unique => true

    db['maps'].create_index 'name', :unique => true

    db['armies'].create_index 'name', :unique => true

    db['games'].create_index 'name', :unique => true

    db['tacktics'].create_index 'name', :unique => true
  end

  def self.seed_users(db)
    coll = db['users']

    encode = ->(val, salt) do
      Digest::SHA2.hexdigest "#{val}--#{salt}"
    end

    users = @@gen.make_users
    users << ADMIN

    users.each do |user|
      t = Time.now.utc
      e_passw = encode.(user[1], t)
      coll.insert({
        'login' => user[0],
        'password' => e_passw,
        'status' => 'offline',
        'sid' => encode.(user[0], Time.now.utc),
        'created_at' => t
      })
    end
  end

  def self.seed_messages(db)
    coll = db['messages']
    db['users'].find.each do |user|
      coll.insert({
        'creator' => user['_id'],
        'text' => "Hello, I'm #{user['login']}",
        'created_at' => Time.now.utc
      })
    end
  end

  def self.seed_units(db)
    coll = db['units']
    h = {}

    units = @@gen.make_units

    units.each_pair do |k, v|
      h[k] = coll.insert({
        'name' => k,
        'rank' => v[0],
        'move_length' => v[1],
        'min_count' => v[2].min,
        'max_count' => v[2].max,
        'description' => v[5],
        'created_at' => Time.now.utc
      })
    end

    units.each_pair do |k, v|
      init_wd = ->(wd) do 
        return [] if wd.nil?
        return :all unless wd.instance_of?(Array)
        wd.map { |el| h[el] }
      end

      win_duels = {
        'attack' => init_wd.(v[3]),
        'protect' => init_wd.(v[4]),
      }
      
      coll.update(
        { 'name' => k },
        {"$set" => { "win_duels" => win_duels } }
      )
    end
  end

  def self.seed_maps(db)
    coll = db['maps']
    admin = db['users'].find_one 'login' => ADMIN[0]
    
    @@gen.make_maps.each do |map|
      map['created_at'] = Time.now.utc
      map['creator'] = admin['_id']
      coll.insert map
    end
  end

  def self.seed_armies(db)
    coll = db['armies']
    admin = db['users'].find_one 'login' => ADMIN[0]
    armies = @@gen.make_armies

    armies.each do |army|
      coll.insert({
        'name' => army['name'],
        'creator' => admin['_id'],
        'units' => army['units'],
        'created_at' => Time.now.utc
      })
    end
  end
end

