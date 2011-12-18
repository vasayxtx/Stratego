#coding: utf-8

require File.join(File.dirname(__FILE__), 'generator')

class Seed
  @@gen = Generator.new

  def self.seed_all(db)
    Seed.seed_users db
    Seed.seed_messages db
    Seed.seed_units db
  end

  def self.create_indexes(db)
    db['users'].create_index 'sid', :unique => true
    db['users'].create_index 'login', :unique => true

    db['messages'].create_index 'owner'

    db['units'].create_index 'name', :unique => true
    db['units'].create_index 'rank', :unique => true
  end

  def self.seed_users(db)
    encode = ->(val) do
      Digest::SHA2.hexdigest "#{val}--#{Time.now.utc}"
    end

    coll = db['users']
    @@gen.make_users.each do |user|
      e_passw = encode.(user[1])
      coll.insert({
        'login' => user[0],
        'password' => e_passw,
        'status' => 'offline',
        'sid' => encode.(e_passw),
        'created_at' => Time.now.utc
      })
    end
  end

  def self.seed_messages(db)
    coll = db['messages']
    db['users'].find.each do |user|
      coll.insert({
        'owner' => user['_id'],
        'text' => "Hello, I'm #{user['login']}",
        'created_at' => Time.now.utc
      })
    end
  end

  def self.seed_units(db)
    coll = db['units']
    units = @@gen.make_units
    units.each_pair do |k, v|
      win_duels = {}
      win_duels['attacks'] = v[3] unless v[3].nil?
      win_duels['protects'] = v[4] unless v[4].nil?
      coll.insert({
        'name' => k,
        'rank' => v[0],
        'move_length' => v[1],
        'min_count' => v[2].min,
        'max_count' => v[2].max,
        'win_duels' => win_duels,
        'description' => v[5],
        'created_at' => Time.now.utc
      })
    end
  end
end

