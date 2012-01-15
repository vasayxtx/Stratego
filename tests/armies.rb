#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'seeds')

CLIENTS_NUM = 5

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

#Test1
#--------------------------------
auth t

#Test2
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
req['name'] = 'ab'
resp = {
  0 => {
    'status' => 'badFieldLenght',
    'message' => 'Length of the name of the army must be in 3..20 characters'
  }
}
t.push_test([[0, req, resp]])

#Test3
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
req['name'] = 'ab#$asfsd'
resp = {
  0 => {
    'status' => 'badFieldFormat',
    'message' => 'Invalid format of name of the army. It must contain only word characters (letter, number, underscore)'
  }
}
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
req['units'] = []
resp = {
  0 => {
    'status' => 'badArmy',
    'message' => 'Incorrect army'
  }
}
t.push_test([[0, req, resp]])

#Test5
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
req['units'][:Flag] = 0
resp = {
  0 => {
    'status' => 'badArmy',
    'message' => 'Incorrect army'
  }
}
t.push_test([[0, req, resp]])

#Test6
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
req['units'][:Chubaka] = 10
resp = {
  0 => {
    'status' => 'badArmy',
    'message' => 'Incorrect army'
  }
}
t.push_test([[0, req, resp]])

#Test7
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
resp = {
  0 => { 'status' => 'ok' }
}
t.push_test([[0, req, resp]])

#Test8
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'createArmy'
resp = {
  0 => {
    'status' => 'badFieldUnique',
    'message' => 'Army with this name already exists'
  }
}
t.push_test([[0, req, resp]])

#Test9
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'editArmy'
req['name'] = 'habrahabr'
resp = {
  0 => {
    'status' => 'badResource',
    'message' => 'Resource is\'t exist'
  }
}
t.push_test([[0, req, resp]])

#Test10
#--------------------------------
req1 = clone Generator::ARMY_MINI
req1['cmd'] = 'createArmy'
resp1 = {
  1 => { 'status' => 'ok' }
}
req0 = clone Generator::ARMY_MINI
req0['cmd'] = 'editArmy'
resp0 = {
  0 => {
    'status' => 'badAccess',
    'message' => 'Illegal access'
  }
}
t.push_test([
  [1, req1, resp1],
  [0, req0, resp0]
])

#Test11
#--------------------------------
req = clone Generator::ARMY_CL
req['cmd'] = 'editArmy'
req['units'] = Generator::ARMY_CL['units']
resp = {
  0 => { 'status' => 'ok' }
}
t.push_test([[0, req, resp]])

#Test12
#--------------------------------
req = { 'cmd' => 'getListAllArmies' }
resp = {
  0 => {
    'status' => 'ok',
    'armies' => [
      Generator::ARMY_CL['name'],
      Generator::ARMY_MINI['name']
    ]
  }
}
t.push_test([[0, req, resp]])

#Test13
#--------------------------------
req0 = { 'cmd' => 'getListArmies' }
req1 = { 'cmd' => 'getListArmies' }
resp0 = {
  0 => {
    'status' => 'ok',
    'armies' => [
      Generator::ARMY_CL['name']
    ]
  }
}
resp1 = {
  1 => {
    'status' => 'ok',
    'armies' => [
      Generator::ARMY_MINI['name']
    ]
  }
}
t.push_test([
  [0, req0, resp0],
  [1, req1, resp1],
])

#Test13
#--------------------------------
req1 = {
  'cmd' => 'destroyArmy',
  'name' => Generator::ARMY_MINI['name']
}
resp1 = {
  1 => { 'status' => 'ok' }
}
req0 = { 'cmd' => 'getListAllArmies' }
resp0 = {
  0 => {
    'status' => 'ok',
    'armies' => [
      Generator::ARMY_CL['name']
    ]
  }
}
t.push_test([
  [1, req1, resp1],
  [0, req0, resp0],
])

#Test14
#--------------------------------
req = {
  'cmd' => 'getArmyUnits',
  'name' => Generator::ARMY_CL['name']
}
units = {}
Generator::ARMY_CL['units'].each_pair do |u_name, u_count|
  units[u_name] = {
    'count' => u_count,
    'minCount' => Generator::UNITS[u_name][2].min,
    'maxCount' => Generator::UNITS[u_name][2].max
  }
end
resp = {
  0 => {
    'status' => 'ok',
    'units' => units
  }
}
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

