#coding: utf-8

require File.join(File.dirname(__FILE__), 'generator')

class Seed
  ADMIN = ['Admin', 'password']

  def self.seed_all(db)
    %w[users units maps armies tactics].each do |n|
      Seed.method("seed_#{n}".to_sym).call(db)
    end
  end

  def self.create_indexes(db)
    indexes = {
      'users'   => %w[sid login],
      'units'   => %w[name rank],
      'maps'    => %w[name],
      'armies'  => %w[name],
      'games'   => %w[name],
      'tactics' => %w[name]
    }
    indexes.each_pair do |k, v|
      v.each { |f| db[k].create_index(f, :unique => true) }
    end
  end

  def self.seed_users(db)
    coll = db['users']

    encode = ->(val, salt) do
      Digest::SHA2.hexdigest("#{val}--#{salt}")
    end

    users = Generator.make_users
    users << ADMIN

    users.each do |user|
      t = Time.now.utc
      e_passw = encode.(user[1], t)
      coll.insert(
        'login'      => user[0],
        'password'   => e_passw,
        'status'     => 'offline',
        'sid'        => encode.(user[0], Time.now.utc),
        'created_at' => t
      )
    end
  end

  def self.seed_units(db)
    coll = db['units']
    h = {}

    units = Generator.make_units

    units.each_pair do |k, v|
      h[k] = coll.insert(
        'name'        => k,
        'rank'        => v[0],
        'move_length' => v[1],
        'min_count'   => v[2].min,
        'max_count'   => v[2].max,
        'description' => v[5],
        'created_at'  => Time.now.utc
      )
    end

    units.each_pair do |k, v|
      init_wd = ->(wd) do 
        return [] if wd.nil?
        return :all unless wd.instance_of?(Array)
        wd.map { |el| h[el] }
      end

      win_duels = {
        'attack'  => init_wd.(v[3]),
        'protect' => init_wd.(v[4]),
      }
      
      coll.update(
        { 'name' => k },
        {"$set"  => { "win_duels" => win_duels } }
      )
    end
  end

  def self.seed_maps(db)
    coll = db['maps']
    admin = db['users'].find_one('login' => ADMIN[0])
    
    Generator.make_maps.each do |map|
      map['created_at'] = Time.now.utc
      map['creator'] = admin['_id']
      coll.insert map
    end
  end

  def self.seed_armies(db)
    coll = db['armies']
    admin = db['users'].find_one('login' => ADMIN[0])
    armies = Generator.make_armies

    armies.each do |army|
      coll.insert(
        'name'       => army['name'],
        'creator'    => admin['_id'],
        'units'      => army['units'],
        'created_at' => Time.now.utc
      )
    end
  end

  def self.seed_tactics(db)
    coll = db['tactics']
    admin = db['users'].find_one('login' => ADMIN[0])

    tactics = [
      [
        Generator::MAP_CL,
        Generator::ARMY_CL,
        Generator::TACTIC_CL
      ],
      [
        Generator::MAP_MINI,
        Generator::ARMY_MINI,
        Generator::TACTIC_MINI
      ],
      [
        Generator::MAP_MINI,
        Generator::ARMY_MINI,
        Generator::TACTIC_TEST
      ]
    ]

    tactics.each do |tactic|
      map   = db['maps'].find_one('name' => tactic[0]['name'])
      army  = db['armies'].find_one('name' => tactic[1]['name'])
      coll.insert(
        'name'       => tactic[2]['name'],
        'map'        => map['_id'],
        'army'       => army['_id'],
        'created_at' => Time.now.utc,
        'placement'  => {
          'pl1' => Generator::make_tactic(tactic[2]),
          'pl2' => Generator::make_tactic(tactic[2])
        }
      )
    end
  end
end

