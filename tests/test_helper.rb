#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'generator')

CLIENTS_NUM = 5

GAME_MINI = 'MiniGame'
REQ_CREATE_GAME_MINI = {
  'cmd'      => 'createGame',
  'name'     => GAME_MINI,
  'nameMap'  => Generator::MAP_MINI['name'],
  'nameArmy' => Generator::ARMY_MINI['name'],
}

def create_maps
  [Generator::MAP_MINI, Generator::MAP_CL].map do |m|
    req = clone(m)
    req['cmd'] = 'createMap'
    [0, req, { 0 => { 'status' => 'ok' } }]
  end
end

def create_armies
  [Generator::ARMY_MINI, Generator::ARMY_CL].map do |a|
    req = clone(a)
    req['cmd'] = 'createArmy'
    [0, req, { 0 => { 'status' => 'ok' } }]
  end
end

def create_tactics
  tactics = []
  [Generator::TACTIC_MINI, Generator::TACTIC_TEST].each do |t|
    tactics << [t, Generator::MAP_MINI, Generator::ARMY_MINI]
  end
  Generator::TACTICS_CL.each do |t|
    tactics << [t, Generator::MAP_CL, Generator::ARMY_CL]
  end
  tactics.map do |t|
    [
      0,
      {
        'cmd'       => 'createTactic',
        'name'      => t[0]['name'],
        'nameMap'   => t[1]['name'],
        'nameArmy'  => t[2]['name'],
        'placement' => {
          'pl1' => Generator::make_tactic(t[0]),
          'pl2' => reflect_placement(
            Generator::make_tactic(t[0]), t[1]['width'] * t[1]['height']),
        }
      },
      { 0 => { 'status' => 'ok' } }
    ]
  end
end

# One player creates game, and second player joins to it
def initial_game_test
  req1 = clone REQ_CREATE_GAME_MINI
  resp1 = { 0 => { 'status' => 'ok' } }
  1.upto(CLIENTS_NUM - 1) do |i|
    resp1[i] = {
      'cmd'  => 'addAvailableGame',
      'name' => GAME_MINI
    }
  end

  req2 = {
    'cmd'  => 'joinGame',
    'name' => GAME_MINI
  }
  resp2 = {
    1 => { 'status' => 'ok' },
    0 => { 'cmd' => 'startGamePlacement' }
  }
  2.upto(CLIENTS_NUM - 1) do |i|
    resp2[i] = { 
      'cmd'  => 'delAvailableGame',
      'name' => GAME_MINI
    }
  end

  [
    *create_maps,
    *create_armies,
    *create_tactics,
    [0, req1, resp1],
    [1, req2, resp2]
  ]
end

def reflect_map(map)
  m = clone map
  size = m['width'] * m['height']

  s = m['structure']
  s['pl1'], s['pl2'] = s['pl2'], s['pl1']

  s.each_value do |a|
    a.each_index { |i| a[i] = size - a[i] - 1 }
  end
  
  m
end

def reflect_placement(placement, map_size)
  h = {}
  placement.each { |k, v| h[(map_size-k.to_i-1).to_s] = v }

  h
end

def reflect_a(a, s)
  a.map { |el| s - el.to_i - 1 }
end

def make_opp_placement(placement, map_size)
  placement.keys.map { |el| map_size - el.to_i - 1 }
end

def make_game_army(a = Generator::ARMY_MINI)
  army = { 'name' => a['name'], 'units' => {} }
  a['units'].each_pair do |u_name, u_count|
    army['units'][u_name] = {
      'count'      => u_count,
      'moveLength' => Generator::UNITS[u_name][1]
    }
  end

  army
end

def make_game_units(a = Generator::ARMY_MINI)
  { 'pl1' => a['units'], 'pl2' => a['units'] }
end
