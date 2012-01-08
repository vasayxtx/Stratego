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

def reflect_map!(map)
  w, h = map['width'], map['height']
  size = w * h

  struct = map['structure']
  struct['pl1'], struct['pl2'] = struct['pl2'], struct['pl1']

  reflect = ->(a) do
    a.each_index { |i| a[i] = size - a[i] - 1 }
  end

  %w[pl1 pl2 obst].each { |a| reflect.(struct[a]) }
end

