#coding: utf-8

class Generator
  
  #***** Users *****
  
  USERS_NUM = 10
  USER = Proc.new { |i| ["User#{i}", 'password'] }

  #***** Maps *****
  
  MAP_CL = {
    'name' => 'ClassicalMap',
    'width' => 10,
    'height' => 10,
    'structure' => {
      'pl1' => (0..39).to_a,
      'pl2' => (60..99).to_a,
      'obst' => [42, 43, 46, 47, 52, 53, 56, 57]
    }
  }

  MAP_MINI = {
    'name' => 'MiniMap',
    'width' => 12,
    'height' => 4,
    'structure' => {
      'pl1' => (0..11).to_a,
      'pl2' => (36..47).to_a,
      'obst' => [12, 23, 24, 35]
    }
  }

  #***** Units *****
  
  U_RANGE = 0..50

  UNITS = {
    'Flag'         => [0,  0,  1..1], 
    'Spy'          => [1,  1,  U_RANGE, ['Marshal']], 
    'Scout'        => [2,  99, U_RANGE], 
    'Miner'        => [3,  1,  U_RANGE, ['Bomb']],
    'Sergeant'     => [4,  1,  U_RANGE], 
    'Lieutenant'   => [5,  1,  U_RANGE], 
    'Captain'      => [6,  1,  U_RANGE], 
    'Major'        => [7,  1,  U_RANGE], 
    'Colonel'      => [8,  1,  U_RANGE], 
    'General'      => [9,  1,  U_RANGE], 
    'Marshal'      => [10, 1,  U_RANGE], 
    'Bomb'         => [-1, 0,  U_RANGE, nil, :all]
  }

  #***** Armies *****
  
  ARMY_CL = {
    'name' => "ClassicalArmy",
    'units' => {
      'Flag' => 1, 
      'Bomb' => 6, 
      'Spy' => 1, 
      'Scout' => 8, 
      'Miner' => 5, 
      'Sergeant' => 4, 
      'Lieutenant' => 4, 
      'Captain' => 4, 
      'Major' => 3, 
      'Colonel' => 2, 
      'General' => 1, 
      'Marshal' => 1
    }
  }

  ARMY_MINI = {
    'name' => "MiniArmy",
    'units' => {
      'Flag' => 1, 
      'Bomb' => 1, 
      'Spy' => 1, 
      'Scout' => 1,
      'Miner' => 1, 
      'Sergeant' => 1, 
      'Lieutenant' => 1, 
      'Captain' => 1, 
      'Major' => 1, 
      'Colonel' => 1, 
      'General' => 1, 
      'Marshal' => 1
    }
  }

  #---------- Tactics ----------
  
  TACTIC_CL = 
  {
    'name' => "Scout's Gambit",
    'placement' => {
      'Flag'        =>  [0], 
      'Bomb'        =>  [1, 10, 14, 19, 21, 26], 
      'Spy'         =>  [17], 
      'Scout'       =>  [4, 7, 9, 24, 27, 30, 34, 39], 
      'Miner'       =>  [3, 5, 12, 18, 36], 
      'Sergeant'    =>  [2, 13, 22, 33], 
      'Lieutenant'  =>  [6, 8, 16, 31], 
      'Captain'     =>  [11, 29, 35, 37], 
      'Major'       =>  [15, 20, 38], 
      'Colonel'     =>  [23, 32], 
      'General'     =>  [28],
      'Marshal'     =>  [25]
    }
  }

  TACTIC_MINI = 
  {
    'name' => "MiniTactic",
    'placement' => {
      'Flag'        =>  [0], 
      'Bomb'        =>  [1], 
      'Spy'         =>  [2], 
      'Scout'       =>  [3], 
      'Miner'       =>  [4], 
      'Sergeant'    =>  [5], 
      'Lieutenant'  =>  [6], 
      'Captain'     =>  [7], 
      'Major'       =>  [8], 
      'Colonel'     =>  [9], 
      'General'     =>  [10], 
      'Marshal'     =>  [11]
    }
  }

  TACTIC_TEST = 
  {
    'name' => "TestTactic",
    'placement' => {
      'Flag'        =>  [1], 
      'Bomb'        =>  [2], 
      'Spy'         =>  [3], 
      'Scout'       =>  [4], 
      'Miner'       =>  [9], 
      'Sergeant'    =>  [0], 
      'Lieutenant'  =>  [5], 
      'Captain'     =>  [6], 
      'Major'       =>  [7], 
      'Colonel'     =>  [11], 
      'General'     =>  [10], 
      'Marshal'     =>  [8]
    }
  }

=begin
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |     |     |     |     |     |     |
  |S(4) |F(0) |B(45)|S(2) |S(3) |L(5) |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
=end

  #***** Methods *****

  def self.make_users(num = USERS_NUM)
    users = Array.new(num) { |i| USER.call(i) }
  end

=begin
  def make_messages(users_num = USERS_NUM)
    hello_msgs = Array.new(users_num) do |i|
      ["Hello, I'm User#{i}"]
    end
    bye_msgs = Array.new(usesr_num) do |i|
      ["By"]
    end

    hello_msgs + bye_msgs
  end
=end

  def self.make_units
    UNITS
  end

  def self.make_maps(map_name = MAP_CL['name'])
    [MAP_CL, MAP_MINI]
  end

  def self.make_armies(map_army = ARMY_CL['name'])
    [ARMY_CL, ARMY_MINI]
  end

  def self.make_tactic(t = TACTIC_CL)
    res = {}
    t['placement'].each_pair do |unit, positions|
      positions.each { |pos| res[pos.to_s] = unit }
    end

    res
  end
end

