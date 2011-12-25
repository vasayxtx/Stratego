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
req = {
  'cmd' => 'createMap',
  'name' => Generator::MAP_CL['name'],
  'width' => 2,
  'height' => 10,
  'structure' => Generator::MAP_CL['structure']
}
resp = {
  0 => {
    'status' => 'badFieldValue',
    'message' => 'Width of the map must be in 3..30'
  }
}
t.push_test([[0, req, resp]])

#Test3
#--------------------------------
req = {
  'cmd' => 'createMap',
  'name' => Generator::MAP_CL['name'],
  'width' => 10,
  'height' => 2,
  'structure' => Generator::MAP_CL['structure']
}
resp = {
  0 => {
    'status' => 'badFieldValue',
    'message' => 'Height of the map must be in 3..30'
  }
}
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
map = clone Generator::MAP_CL
map['structure']['pl1'] << 40 #Different sizes
req = {
  'cmd' => 'createMap',
  'name' => map['name'],
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test5
#--------------------------------
map = clone Generator::MAP_CL
map['structure']['pl1'][0] = 100  #Incorrect value
req = {
  'cmd' => 'createMap',
  'name' => map['name'],
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test6
#--------------------------------
map = clone Generator::MAP_CL
map['structure']['pl1'][1] = 0  #Not unique values
req = {
  'cmd' => 'createMap',
  'name' => map['name'],
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test7
#--------------------------------
map = clone Generator::MAP_CL
map['structure']['pl1'][1] = 60  #Collisions
req = {
  'cmd' => 'createMap',
  'name' => map['name'],
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badMap',
    'message' => 'Incorrect map'
  }
}
t.push_test([[0, req, resp]])

#Test8
#--------------------------------
map = clone Generator::MAP_CL
req = {
  'cmd' => 'createMap',
  'name' => 'ab',
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badFieldLenght',
    'message' => 'Length of the name of the must be in 3..20 characters'
  }
}
t.push_test([[0, req, resp]])

#Test9
#--------------------------------
map = clone Generator::MAP_CL
req = {
  'cmd' => 'createMap',
  'name' => 'abcd!~#sdf',
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badFieldFormat',
    'message' => 'Invalid format of name of the map. It must contain only word characters (letter, number, underscore)'
  }
}
t.push_test([[0, req, resp]])

#Test10
#--------------------------------
map = clone Generator::MAP_CL
req = {
  'cmd' => 'createMap',
  'name' => map['name'],
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = { 0 => { 'status' => 'ok' } }
t.push_test([[0, req, resp]])

#Test11
#--------------------------------
map = Generator::MAP_CL
req = {
  'cmd' => 'createMap',
  'name' => map['name'],  #Not unique name
  'width' => map['width'],
  'height' => map['height'],
  'structure' => map['structure']
}
resp = {
  0 => {
    'status' => 'badFieldUnique',
    'message' => 'Map with this name already exists'
  }
}
t.push_test([[0, req, resp]])

#Test
#--------------------------------
logout t

t.run

