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
reflect_map!(r1['map'])
t.push_test([
  [0, req, { 0 => r0 }],
  [1, req, { 1 => r1 }],
])
=begin
#Test5
#--------------------------------
req = { 'cmd' => 'setPlacement' }
r0 = {
  'status' => 'ok',
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
=end
#Test
#--------------------------------
logout t

t.run

