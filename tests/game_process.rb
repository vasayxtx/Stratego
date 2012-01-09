#coding: utf-8

require File.join(File.dirname(__FILE__), 'game_helper')

t = Tester.new(CLIENTS_NUM) do |i|
  ["User#{i}", 'password']
end

MAP_SIZE = Generator::MAP_MINI['width'] * Generator::MAP_MINI['height']

def make_move(p_from, p_to)
  [
    {
      'cmd' => 'makeMove',
      'posFrom' => p_from,
      'posTo' => p_to
    },
    {
      'cmd' => 'makeMove',
      'posFrom' => MAP_SIZE - p_from - 1,
      'posTo' => MAP_SIZE - p_to - 1
    }
  ]
end

#Test1
#--------------------------------
auth t

#Test2 
#--------------------------------
t.push_test(initial_game_test)

#Test3
#--------------------------------
=begin

    11    10     9     8     7     6     5     4     3     2     1     0 
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  | C(8)| G(9)| M(3)|M(10)| M(7)| C(6)| L(5)| S(2)| S(1)|B(-1)| F(0)| S(4)|
  |     |     |     |  &  |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |  *  |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |     |     |     |     |     |     |
  |S(4) |F(0) |B(-1)|S(1) |S(2) |L(5) |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
     0     1     2     3     4     5     6     7     8     9     10    11 

=end

resp = {
  1 => {
    'status' => 'badAction',
    'message' => 'Game isn\'t started'
  }
}
t.push_test([[1, make_move(8, 20)[0], resp]])

#Test4
#--------------------------------
req = {
  'cmd' => 'setPlacement',
  'placement' => Generator.make_tactic(Generator::TACTIC_TEST)
}
resp0 = {
  1 => {
    'status' => 'ok',
    'isGameStarted' => false
  },
  0 => { 'cmd' => 'readyOpponent' }
}
resp1 = {
  0 => {
    'status' => 'ok',
    'isGameStarted' => true
  },
  1 => { 'cmd' => 'startGame' }
}
t.push_test([
  [1, req, resp0],
  [0, req, resp1]
])

#Test5
#--------------------------------
=begin

    11    10     9     8     7     6     5     4     3     2     1     0 
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  | C(8)| G(9)| M(3)|M(10)| M(7)| C(6)| L(5)| S(2)| S(1)|B(-1)| F(0)| S(4)|
  |     |     |     |  &  |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |  *  |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |     |     |     |     |     |     |
  |S(4) |F(0) |B(-1)|S(1) |S(2) |L(5) |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
     0     1     2     3     4     5     6     7     8     9     10    11 

=end

resp = {
  1 => {
    'status' => 'badAction',
    'message' => 'It isn\'t your turn now'
  }
}
t.push_test([[1, make_move(8, 20)[0], resp]])

#Test5 (bad positions)
#--------------------------------
resp = {
  0 => {
    'status' => 'badMove',
    'message' => 'Incorrect move'
  }
}
test = [
  [-1, 0],
  [48, 47],
  [0, -1],
  [47, 48],
  [13, 14],
  [1, 2],
  [0, 12],
].map { |el| [0, make_move(el[0], el[1])[0], resp] }
t.push_test(test)

#Test6 (bad lenght of the move)
#--------------------------------
resp = {
  0 => {
    'status' => 'badMove',
    'message' => 'Incorrect move'
  }
}
test = [
  [0, 13],
  [1, 13],
  [2, 14],
  [3, 27],
].map { |el| [0, make_move(el[0], el[1])[0], resp] }
t.push_test(test)

#--------------------------------------------------------------------------
cl0_pl1 = Generator::make_tactic Generator::TACTIC_TEST
cl1_pl1 = clone cl0_pl1

#Test7
#--------------------------------
=begin

    11    10     9     8     7     6     5     4     3     2     1     0 
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  | C(8)| G(9)| M(3)|M(10)| M(7)| C(6)| L(5)| S(2)| S(1)|B(-1)| F(0)| S(4)|
  |     |     |     |     |     |     |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |  &  |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |  *  |     |     |     |     |     |     |
  |S(4) |F(0) |B(-1)|S(1) |S(2) |L(5) |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
     0     1     2     3     4     5     6     7     8     9     10    11 

=end

req, resp1 = make_move 5, 17
resp = {
  0 => { 'status' => 'ok' },
  1 => resp1
}
t.push_test([[0, req, resp]])

#Test8
#--------------------------------
=begin

    11    10     9     8     7     6     5     4     3     2     1     0 
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  | C(8)| G(9)| M(3)|M(10)| M(7)| C(6)| L(5)| S(2)| S(1)|B(-1)| F(0)| S(4)|
  |     |     |     |     |     |  *  |     |     |     |     |     |     |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |  &  |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |xxxxx|     |     |     |     |     |     |     |     |     |     |xxxxx|
  |xxxxx|     |     |     |     |L(5) |     |     |     |     |     |xxxxx|
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |     |     |     |     |     |     |
  |S(4) |F(0) |B(-1)|S(1) |S(2) |     |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
     0     1     2     3     4     5     6     7     8     9     10    11 

=end

req, resp0 = make_move 6, 18
resp = {
  1 => { 'status' => 'ok' },
  0 => resp0
}
t.push_test([[1, req, resp]])

=begin
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
      'state' => states[i],
      'isTurn' => i == 0
    }
  }
end

t.push_test([
  [0, req, resp[0]],
  [1, req, resp[1]],
])
=end

#Test
#--------------------------------
logout t

t.run

