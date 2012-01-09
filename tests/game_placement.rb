#coding: utf-8

require File.join(File.dirname(__FILE__), 'game_helper')

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

state0 = Generator.make_tactic Generator::TACTIC_MINI
resp0 = {
  0 => {
    'status' => 'ok',
    'game_name' => GAME_MINI,
    'players' => %w[User0 User1],
    'map' => clone(Generator::MAP_MINI),
    'army' => Generator::ARMY_MINI,
    'state' => state0
  }
}
resp0[0]['map']['structure'].delete 'pl1'

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

states[0] = Generator.make_tactic Generator::TACTIC_MINI
maps[0] = clone Generator::MAP_MINI

states[1] = reflect_placement(
  Generator.make_tactic(Generator::TACTIC_TEST), 
  Generator::MAP_MINI['width'] * Generator::MAP_MINI['height']
)
maps[1] = reflect_map Generator::MAP_MINI

resp = Array.new(2) do |i|
  maps[i]['structure'].delete 'pl1'
  {
    i => {
      'status' => 'ok',
      'game_name' => GAME_MINI,
      'players' => %w[User0 User1],
      'map' => maps[i],
      'army' => Generator::ARMY_MINI,
      'state' => states[i]
    }
  }
end

t.push_test([
  [0, req, resp[0]],
  [1, req, resp[1]],
])

#Test
#--------------------------------
logout t

t.run

