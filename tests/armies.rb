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
resp = {
  0 => { 'status' => 'ok' }
}
t.push_test([[0, req0, resp0]])

#Test12
#--------------------------------
=begin
req = clone Generator::ARMY_CL
req['cmd'] = 'editArmy'
resp = {
  0 => { 'status' => 'ok' }
}
t.push_test([[0, req0, resp0]])
=end

#Test
#--------------------------------
logout t

t.run

