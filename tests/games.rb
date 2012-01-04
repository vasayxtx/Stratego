#coding: utf-8

require File.join(File.dirname(__FILE__), 'tester')
require File.join(File.dirname(__FILE__), '..', 'db', 'generator')

CLIENTS_NUM = 5

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

GAME_CL = 'ClassicalGame'
REQ_CREATE_GAME_CL = {
  'cmd' => 'createGame',
  'name' => GAME_CL,
  'nameMap' => Generator::MAP_CL['name'],
  'nameArmy' => Generator::ARMY_CL['name'],
}

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

#Test2 (Creation of the map/army)
#--------------------------------

req0 = clone Generator::MAP_CL
req0['cmd'] = 'createMap'
req1 = clone Generator::MAP_MINI
req1['cmd'] = 'createMap'
req2 = clone Generator::ARMY_CL
req2['cmd'] = 'createArmy'
resp = { 0 => { 'status' => 'ok' } }
t.push_test([
  [0, req0, resp],
  [0, req1, resp],
  [0, req2, resp]
])

#Test3
#--------------------------------
req = clone REQ_CREATE_GAME_CL
req['name'] = 'ab'
resp = { 
  0 => { 
    'status' => 'badFieldLenght',
    'message' => 'Length of the name of the game must be in 3..20 characters'
  }
}
t.push_test([[0, req, resp]])

#Test4
#--------------------------------
req = clone REQ_CREATE_GAME_CL
req['name'] = 'afdfda$#%31'
resp = { 
  0 => { 
    'status' => 'badFieldFormat',
    'message' => 'Invalid format of name of the game. It must contain only word characters (letter, number, underscore)'
  }
}
t.push_test([[0, req, resp]])

#Test5
#--------------------------------
req = clone REQ_CREATE_GAME_CL
req['nameMap'] = 'safasdf'
resp = { 
  0 => { 
    'status' => 'badResource',
    'message' => 'Resource is\'t exist'
  }
}
t.push_test([[0, req, resp]])

#Test6
#--------------------------------
req = clone REQ_CREATE_GAME_CL
req['nameArmy'] = 'safasdf'
resp = { 
  0 => { 
    'status' => 'badResource',
    'message' => 'Resource is\'t exist'
  }
}
t.push_test([[0, req, resp]])

#Test7
#--------------------------------
req = clone REQ_CREATE_GAME_CL
req['nameMap'] = Generator::MAP_MINI['name']
resp = { 
  0 => { 
    'status' => 'badGame',
    'message' => 'Incorrect game'
  }
}
t.push_test([[0, req, resp]])

#Test8
#--------------------------------
req = clone REQ_CREATE_GAME_CL
resp = { 0 => { 'status' => 'ok' } }
1.upto(CLIENTS_NUM - 1) do |i|
  resp[i] = {
    'cmd' => 'addAvailableGame',
    'name' => GAME_CL
  }
end
t.push_test([[0, req, resp]])

#Test9
#--------------------------------
req = clone REQ_CREATE_GAME_CL
resp = {
  0 => { 
    'status' => 'badFieldUnique',
    'message' => 'Game with this name already exists'
  }
}
t.push_test([[0, req, resp]])

#Test10
#--------------------------------
req = {
  'cmd' => 'getGameParams',
  'name' => GAME_CL
}
resp = {
  0 => { 
    'status' => 'ok',
    'map' => Generator::MAP_CL,
    'army' => Generator::ARMY_CL
  }
}
t.push_test([[0, req, resp]])

#Test11
#--------------------------------
req = {
  'cmd' => 'joinGame',
  'name' => GAME_CL
}
resp = {
  1 => { 'status' => 'ok' },
  0 => { 'cmd' => 'startGamePlacement' }
}
2.upto(CLIENTS_NUM - 1) do |i|
  resp[i] = { 
    'cmd' => 'delAvailableGame',
    'name' => GAME_CL
  }
end
t.push_test([[1, req, resp]])

#Test12
#--------------------------------
req = clone REQ_CREATE_GAME_MINI
resp0 = { 
  0 => { 
    'status' => 'badAction',
    'message' => 'User already in a game'
  }
}
resp1 = { 
  1 => { 
    'status' => 'badAction',
    'message' => 'User already in a game'
  }
}
t.push_test([
  [0, req, resp0],
  [1, req, resp1]
])

#Test13
#--------------------------------
req = clone REQ_CREATE_GAME_MINI
resp0 = { 
  0 => { 
    'status' => 'badAction',
    'message' => 'User already in a game'
  }
}
resp1 = { 
  1 => { 
    'status' => 'badAction',
    'message' => 'User already in a game'
  }
}
t.push_test([
  [0, req, resp0],
  [1, req, resp1]
])

#Test
#--------------------------------
logout t

t.run

