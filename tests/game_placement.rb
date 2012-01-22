#coding: utf-8

require File.join(File.dirname(__FILE__), 'test_helper')

MAP_MINI_SIZE = Generator::MAP_MINI['width'] * Generator::MAP_MINI['height']

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

M = h_slice(Generator::MAP_MINI, %w[name width height])
M['obst'] = Generator::MAP_MINI['structure']['obst']

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
  'map' => M,
  'army' => Generator::ARMY_MINI,
  'state' => {
    'pl1' => Generator::MAP_MINI['structure']['pl1'],
    'pl2' => Generator::MAP_MINI['structure']['pl2'],
  }
}
r1 = clone r0
r1['state'] = {
  'pl1' => reflect_a(Generator::MAP_MINI['structure']['pl2'], MAP_MINI_SIZE),
  'pl2' => reflect_a(Generator::MAP_MINI['structure']['pl1'], MAP_MINI_SIZE),
}
r1['map']['obst'] = reflect_a r1['map']['obst'], MAP_MINI_SIZE

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
r0 = {
  'status' => 'ok',
  'game_name' => GAME_MINI,
  'players' => %w[User0 User1],
  'map' => M,
  'army' => Generator::ARMY_MINI,
  'state' => {
    'pl1' => Generator::make_tactic(Generator::TACTIC_MINI),
    'pl2' => Generator::MAP_MINI['structure']['pl2'],
  }
}
r1 = clone r0
r1['state'] = {
  'pl1' => reflect_a(Generator::MAP_MINI['structure']['pl2'], MAP_MINI_SIZE),
  'pl2' => reflect_a(Generator::MAP_MINI['structure']['pl1'], MAP_MINI_SIZE),
}
r1['map']['obst'] = reflect_a r1['map']['obst'], MAP_MINI_SIZE

t.push_test([
  [0, req, { 0 => r0 }],
  [1, req, { 1 => r1 }],
])

#Test7
#--------------------------------
tactics = {}
[Generator::TACTIC_MINI, Generator::TACTIC_TEST].each do |t|
  tactics[t['name']] = Generator::make_tactic(t)
end
req = { 'cmd' => 'getGameTactics' }
resp0 = {
  0 => {
    'status' => 'ok',
    'tactics' => tactics
  }
}
tactics = {}
[Generator::TACTIC_MINI, Generator::TACTIC_TEST].each do |t|
  tactics[t['name']] = reflect_placement(Generator::make_tactic(t), MAP_MINI_SIZE)
end
resp1 = {
  1 => {
    'status' => 'ok',
    'tactics' => tactics
  }
}
t.push_test([[0, req, resp0]])
t.push_test([[1, req, resp1]])

#Test8
#--------------------------------
placement = Generator.make_tactic(Generator::TACTIC_TEST)
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

#Test9
#--------------------------------
req = { 'cmd' => 'getGame' }
r0 = {
  'status' => 'ok',
  'game_name' => GAME_MINI,
  'players' => %w[User0 User1],
  'map' => M,
  'army' => Generator::ARMY_MINI,
  'isTurn' => true,
  'state' => {
    'pl1' => Generator::make_tactic(Generator::TACTIC_MINI),
    'pl2' => make_opp_placement(Generator::make_tactic(Generator::TACTIC_TEST), MAP_MINI_SIZE),
  }
}
r1 = clone r0
r1['state'] = {
  'pl1' => Generator::make_tactic(Generator::TACTIC_TEST),
  'pl2' => make_opp_placement(Generator::make_tactic(Generator::TACTIC_MINI), MAP_MINI_SIZE),
}
r1['map']['obst'] = reflect_a r1['map']['obst'], MAP_MINI_SIZE
r1['isTurn'] = false

t.push_test([
  [0, req, { 0 => r0 }],
  [1, req, { 1 => r1 }],
])

#Test10
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
