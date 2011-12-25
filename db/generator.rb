#coding: utf-8

class Generator
  
  #***** Users *****
  
  USERS_NUM = 10
  USER = Proc.new { |i| ["User#{i}", 'password'] }

  #***** Maps *****
  
  MAP_CL = {
    :name => "ClassicalMap",
    :width => 10,
    :height => 10,
    :pl1 => 0..39,
    :pl2 => 60..99,
    :obst => [42, 43, 46, 47, 52, 53, 56, 57]
  }

  MAP_MINI = {
    :n => "MiniMap",
    :w => 12,
    :h => 4,
    :pl1 => 0..11,
    :pl2 => 36..47,
    :obst => [12, 23, 24, 35]
  }

  #***** Units *****
  
  U_RANGE = 0..50

  UNITS = {
    :Flag         => [0,  0,  1..1], 
    :Spy          => [1,  1,  U_RANGE, [:Marshal]], 
    :Scout        => [2,  99, U_RANGE], 
    :Miner        => [3,  1,  U_RANGE, [:Bomb]],
    :Sergeant     => [4,  1,  U_RANGE], 
    :Lieutenant   => [5,  1,  U_RANGE], 
    :Captain      => [6,  1,  U_RANGE], 
    :Major        => [7,  1,  U_RANGE], 
    :Colonel      => [8,  1,  U_RANGE], 
    :General      => [9,  1,  U_RANGE], 
    :Marshal      => [10, 1,  U_RANGE], 
    :Bomb         => [-1, 0,  U_RANGE, nil, :all]
  }

  #***** Armies *****
  
  ARMY_CL = {
    :name => "ClassicalArmy",
    :units => [
      [:Flag, 1], 
      [:Bomb, 6], 
      [:Spy, 1], 
      [:Scout, 8], 
      [:Miner, 5], 
      [:Sergeant, 4], 
      [:Lieutenant, 4], 
      [:Captain, 4], 
      [:Major, 3], 
      [:Colonel, 2], 
      [:General, 1], 
      [:Marshal, 1]
    ]
  }

  ARMY_MINI = {
    :name => "MiniArmy",
    :units => [
      [:Flag, 1], 
      [:Bomb, 1], 
      [:Spy, 1], 
      [:Scout, 1], 
      [:Miner, 1], 
      [:Sergeant, 1], 
      [:Lieutenant, 1], 
      [:Captain, 1], 
      [:Major, 1], 
      [:Colonel, 1], 
      [:General, 1], 
      [:Marshal, 1]
    ]
  }

  #***** Methods *****

  def make_users(num = USERS_NUM)
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

  def make_units
    UNITS
  end

  def make_map(map_name = MAP_CL[:name])

  end
end

