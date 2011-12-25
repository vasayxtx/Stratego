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
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['width'] = 2 #Bad value of the width
resp = {
  0 => {
    'status' => 'badFieldValue',
    'message' => 'Width of the map must be in 3..30'
  }
}
t.push_test([[0, req, resp]])

#Test3
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['height'] = 2 #Bad value of the height
resp = {
  0 => {
    'status' => 'badFieldValue',
    'message' => 'Height of the map must be in 3..30'
  }
}
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['structure']['pl1'] << 40 #Different sizes
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test5
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['structure']['pl1'][0] = 100  #Incorrect value
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test6
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['structure']['pl1'][1] = 0  #Not unique values
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test7
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['structure']['pl1'][1] = 60  #Collisions
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test8
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['name'] = 'ab' #Bad length
resp = {
  0 => {
    'status' => 'badFieldLenght',
    'message' => 'Length of the name of the must be in 3..20 characters'
  }
}
t.push_test([[0, req, resp]])

#Test9
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
req['name'] = 'abcd!~#sdf' #Bad format
resp = {
  0 => {
    'status' => 'badFieldFormat',
    'message' => 'Invalid format of name of the map. It must contain only word characters (letter, number, underscore)'
  }
}
t.push_test([[0, req, resp]])

#Test10
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
resp = { 0 => { 'status' => 'ok' } }
t.push_test([[0, req, resp]])

#Test11
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'createMap'
resp = {
  0 => {
    'status' => 'badFieldUnique',
    'message' => 'Map with this name already exists'
  }
}
t.push_test([[0, req, resp]])

#Test12
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'editMap'
req['name'] = 'habrahabr'  #Not exists
resp = {
  0 => {
    'status' => 'badResource',
    'message' => 'Resource is\'t exist'
  }
}
t.push_test([[0, req, resp]])

#Test13
#--------------------------------
req = clone Generator::MAP_CL
req['cmd'] = 'editMap'
resp = { 0 => { 'status' => 'ok' } }
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

