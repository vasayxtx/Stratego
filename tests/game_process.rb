#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'generator')

CLIENTS_NUM = 5

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

GAME_MINI = 'MiniGame'
REQ_CREATE_GAME_MINI = {
  'cmd' => 'createGame',
  'name' => GAME_MINI,
  'nameMap' => Generator::MAP_MINI['name'],
  'nameArmy' => Generator::ARMY_MINI['name'],
}

#Test1
#--------------------------------
auth t

#Test2 (Creation of the map/army/game. Join to the game)
#--------------------------------
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

t.push_test([
  [0, req0, resp0],
  [0, req1, resp0],
  [0, req2, resp1],
  [1, req3, resp2]
])

#Test3
#--------------------------------
req = { 'cmd' => 'getGame' }
resp = {
  2 => {
    'status' => 'badAction',
    'message' => 'User isn\'t player of this game'
  },
}
t.push_test([[2, req, resp]])

#Test4
#--------------------------------
req = { 'cmd' => 'getGame' }
r0 = {
  'status' => 'ok',
  'game_status' => 'placement',
  'game_name' => GAME_MINI,
  'players' => %w[User0 User1],
  'map' => Generator::MAP_MINI,
  'army' => Generator::ARMY_MINI
}
r1 = clone r0
reflect_map!(r1['map'])
t.push_test([
  [0, req, { 0 => r0 }],
  [1, req, { 1 => r1 }],
])

#Test
#--------------------------------
logout t

t.run

