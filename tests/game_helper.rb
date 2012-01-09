#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'generator')

CLIENTS_NUM = 5

GAME_MINI = 'MiniGame'
REQ_CREATE_GAME_MINI = {
  'cmd' => 'createGame',
  'name' => GAME_MINI,
  'nameMap' => Generator::MAP_MINI['name'],
  'nameArmy' => Generator::ARMY_MINI['name'],
}

#Creation of the map/army/game. Join to the game
def initial_game_test
  req0 = clone Generator::MAP_MINI
  req0['cmd'] = 'createMap'
  req1 = clone Generator::ARMY_MINI
  req1['cmd'] = 'createArmy'
  resp0 = { 0 => { 'status' => 'ok' } }

  req2 = clone REQ_CREATE_GAME_MINI
  resp1 = { 0 => { 'status' => 'ok' } }
  1.upto(CLIENTS_NUM - 1) do |i|
    resp1[i] = {
      'cmd' => 'addAvailableGame',
      'name' => GAME_MINI
    }
  end

  req3 = {
    'cmd' => 'joinGame',
    'name' => GAME_MINI
  }
  resp2 = {
    1 => { 'status' => 'ok' },
    0 => { 'cmd' => 'startGamePlacement' }
  }
  2.upto(CLIENTS_NUM - 1) do |i|
    resp2[i] = { 
      'cmd' => 'delAvailableGame',
      'name' => GAME_MINI
    }
  end

  [
    [0, req0, resp0],
    [0, req1, resp0],
    [0, req2, resp1],
    [1, req3, resp2]
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

