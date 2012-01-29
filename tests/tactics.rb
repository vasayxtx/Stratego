#coding: utf-8

require File.join(File.dirname(__FILE__), 'test_helper')

MAP = Generator::MAP_MINI
M_SIZE = MAP['width'] * MAP['height']

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

#Test1
#--------------------------------
auth t

#Test2 
#--------------------------------
t.push_test([*create_maps, *create_armies])

#Test3
#--------------------------------
req = {
  'cmd'       => 'createTactic',
  'name'      => Generator::TACTIC_MINI['name'],
  'nameMap'   => Generator::MAP_MINI['name'],
  'nameArmy'  => Generator::ARMY_MINI['name'],
  'placement' => {
    'pl1' => Generator::make_tactic(Generator::TACTIC_MINI),
    'pl2' => reflect_placement(
      Generator::make_tactic(Generator::TACTIC_MINI), M_SIZE),
  }
}
resp = { 0 => { 'status' => 'ok' } }
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
req = {
  'cmd'  => 'destroyMap',
  'name' => Generator::MAP_MINI['name'],
}
resp = { 0 => {
  'status' => 'badAction',
  'message' => 'Map used in the tactics'
} }
t.push_test([[0, req, resp]])

#Test5
#--------------------------------
req = {
  'cmd'  => 'destroyArmy',
  'name' => Generator::ARMY_MINI['name'],
}
resp = { 0 => {
  'status' => 'badAction',
  'message' => 'Army used in the tactics'
} }
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

