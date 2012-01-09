#coding: utf-8

require File.join(File.dirname(__FILE__), 'game_helper')

MAP_SIZE = Generator::MAP_MINI['width'] * Generator::MAP_MINI['height']

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

#Test1
#--------------------------------
auth t

#Test2 
#--------------------------------
t.push_test(initial_game_test)

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
  'game_name' => GAME_MINI,
  'players' => %w[User0 User1],
  'map' => Generator::MAP_MINI,
  'army' => Generator::ARMY_MINI
}
r1 = clone r0
r1['map'] = reflect_map r1['map']

t.push_test([
  [0, req, { 0 => r0 }],
  [1, req, { 1 => r1 }],
])

#Test5
#--------------------------------
placement = Generator.make_tactic Generator::TACTIC_MINI
req = {
  'cmd' => 'setPlacement',
  'placement' => placement
}
resp = {
  0 => {
    'status' => 'ok',
    'isGameStarted' => false
  },
  1 => { 'cmd' => 'readyOpponent' }
}
t.push_test([[0, req, resp]])

#Test6
#--------------------------------
req = { 'cmd' => 'getGame' }

state0 = {
  'pl1' => Generator.make_tactic(Generator::TACTIC_MINI),
  'pl2' => Generator::MAP_MINI['structure']['pl2']
}
resp0 = {
  0 => {
    'status' => 'ok',
    'game_name' => GAME_MINI,
    'players' => %w[User0 User1],
    'map' => h_slice(Generator::MAP_MINI, %w[name width height]),
    'army' => Generator::ARMY_MINI,
    'state' => state0
  }
}
resp0[0]['map']['obst'] = Generator::MAP_MINI['structure']['obst']

resp1 = {
  1 => {
    'status' => 'ok',
    'game_name' => GAME_MINI,
    'players' => %w[User0 User1],
    'map' => reflect_map(Generator::MAP_MINI),
    'army' => Generator::ARMY_MINI
  }
}

t.push_test([
  [0, req, resp0],
  [1, req, resp1],
])

#Test7
#--------------------------------
placement = Generator.make_tactic Generator::TACTIC_TEST
req = {
  'cmd' => 'setPlacement',
  'placement' => placement
}
resp = {
  1 => {
    'status' => 'ok',
    'isGameStarted' => true
  },
  0 => { 'cmd' => 'startGame' }
}
t.push_test([[1, req, resp]])

#Test8
#--------------------------------
req = { 'cmd' => 'getGame' }

states = Array.new(2)
maps = Array.new(2)

p1 = Generator.make_tactic(Generator::TACTIC_MINI)
p2 = Generator.make_tactic(Generator::TACTIC_TEST)
states[0] = { 'pl1' => p1, 'pl2' => reflect_a(p2.keys, MAP_SIZE) }
states[1] = { 'pl1' => p2, 'pl2' => reflect_a(p1.keys, MAP_SIZE) }

maps[0] = h_slice Generator::MAP_MINI, %w[name width height]
maps[1] = clone maps[0]
maps[0]['obst'] = Generator::MAP_MINI['structure']['obst']
maps[1]['obst'] = reflect_a(maps[0]['obst'], MAP_SIZE)

resp = Array.new(2) do |i|
  {
    i => {
      'status' => 'ok',
      'game_name' => GAME_MINI,
      'players' => %w[User0 User1],
      'map' => maps[i],
      'army' => Generator::ARMY_MINI,
      'state' => states[i],
      'isTurn' => i == 0
    }
  }
end

t.push_test([
  [0, req, resp[0]],
  [1, req, resp[1]],
])

#Test9
#--------------------------------
req = { 'cmd' => 'leaveGame' }
resp = {
  0 => { 'status' => 'ok' },
  1 => { 'cmd' => 'endGame' }
}
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

