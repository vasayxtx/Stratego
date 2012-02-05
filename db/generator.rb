#coding: utf-8

class Generator
  
  #***** Users *****
  
  USERS_NUM = 10
  USER = Proc.new { |i| ["User#{i}", 'password'] }

  #***** Maps *****
  
  MAP_CL = {
    'name'      => 'ClassicalMap',
    'width'     => 10,
    'height'    => 10,
    'structure' => {
      'pl1'  => (0..39).to_a,
      'pl2'  => (60..99).to_a,
      'obst' => [42, 43, 46, 47, 52, 53, 56, 57]
    }
  }

  MAP_MINI = {
    'name'      => 'MiniMap',
    'width'     => 12,
    'height'    => 4,
    'structure' => {
      'pl1'  => (0..11).to_a,
      'pl2'  => (36..47).to_a,
      'obst' => [12, 23, 24, 35]
    }
  }

  MAP_AI = {
    'name'      => 'AiMap',
    'width'     => 10,
    'height'    => 6,
    'structure' => {
      'pl1'  => (0..19).to_a,
      'pl2'  => (40..59).to_a,
      'obst' => [22, 23, 28, 32, 33, 38]
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
    'name'  => "ClassicalArmy",
    'units' => {
      'Flag'       => 1, 
      'Bomb'       => 6, 
      'Spy'        => 1, 
      'Scout'      => 8, 
      'Miner'      => 5, 
      'Sergeant'   => 4, 
      'Lieutenant' => 4, 
      'Captain'    => 4, 
      'Major'      => 3, 
      'Colonel'    => 2, 
      'General'    => 1, 
      'Marshal'    => 1
    }
  }

  ARMY_MINI = {
    'name'  => 'MiniArmy',
    'units' => {
      'Flag'       => 1,
      'Bomb'       => 1,
      'Spy'        => 1,
      'Scout'      => 1,
      'Miner'      => 1,
      'Sergeant'   => 1,
      'Lieutenant' => 1,
      'Captain'    => 1,
      'Major'      => 1,
      'Colonel'    => 1,
      'General'    => 1,
      'Marshal'    => 1
    }
  }

  ARMY_AI = {
    'name'  => 'AiArmy',
    'units' => {
      'Flag'       => 1,
      'Bomb'       => 4,
      'Spy'        => 1,
      'Scout'      => 4,
      'Miner'      => 2,
      'Sergeant'   => 1,
      'Lieutenant' => 1, 
      'Captain'    => 1,
      'Major'      => 1,
      'Colonel'    => 2,
      'General'    => 1,
      'Marshal'    => 1
    }
  }

  #---------- Tactics ----------
  
  TACTICS_CL = [
    {
      'name'      => 'CycloneDefence',
      'placement' => {
        'Flag'        =>  [12],
        'Bomb'        =>  [2, 11, 13, 22, 28, 39],
        'Spy'         =>  [10],
        'Scout'       =>  [4, 5, 7, 9, 17, 30, 33, 37],
        'Miner'       =>  [14, 23, 26, 27, 32],
        'Sergeant'    =>  [1, 3, 18, 29],
        'Lieutenant'  =>  [6, 8, 16, 35],
        'Captain'     =>  [19, 21, 25, 34],
        'Major'       =>  [0, 31, 36],
        'Colonel'     =>  [24, 38],
        'General'     =>  [15],
        'Marshal'     =>  [20]
      }
    },
    {
      'name'      => 'ScoutGambit',
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
    },
    {
      'name'      => 'TheTempestDefense',
      'placement' => {
        'Flag'        => [1],
        'Bomb'        => [0, 2, 11, 13, 16, 20],
        'Spy'         => [17],
        'Scout'       => [4, 7, 21, 22, 29, 30, 34, 37],
        'Miner'       => [6, 8, 15, 23, 27],
        'Sergeant'    => [3, 19, 35, 39],
        'Lieutenant'  => [5, 12, 18, 26],
        'Captain'     => [14, 25, 33, 36],
        'Major'       => [9, 10, 31],
        'Colonel'     => [24, 38],
        'General'     => [32],
        'Marshal'     => [28]
      }
    },
    {
      'name'      => 'TrippleThreat',
      'placement' => {
        'Flag'        => [1],
        'Bomb'        => [0, 2, 3, 4, 8, 11],
        'Spy'         => [27],
        'Scout'       => [5, 7, 13, 23, 24, 30, 34, 38],
        'Miner'       => [9, 14, 15, 19, 36],
        'Sergeant'    => [18, 20, 29, 39],
        'Lieutenant'  => [6, 10, 22, 35],
        'Captain'     => [17, 21, 25, 33],
        'Major'       => [12, 16, 28],
        'Colonel'     => [32, 37],
        'General'     => [31],
        'Marshal'     => [26]
      }
    },
    {
      'name'      => 'OnGuard',
      'placement' => {
        'Flag'        => [2],
        'Bomb'        => [1, 3, 12, 25, 27, 28],
        'Spy'         => [23],
        'Scout'       => [4, 5, 9, 18, 20, 30, 35, 39],
        'Miner'       => [13, 15, 19, 24, 32],
        'Sergeant'    => [0, 6, 7, 31],
        'Lieutenant'  => [14, 17, 21, 26],
        'Captain'     => [8, 16, 36, 37],
        'Major'       => [11, 34, 38],
        'Colonel'     => [22, 29],
        'General'     => [10],
        'Marshal'     => [33]
      }
    },
    {
      'name'      => 'ShorelineBluff',
      'placement' => {
        'Flag'        => [32],
        'Bomb'        => [7, 13, 16, 31, 33, 37],
        'Spy'         => [10],
        'Scout'       => [0, 4, 5, 9, 26, 30, 35, 39],
        'Miner'       => [1, 6, 15, 24, 28],
        'Sergeant'    => [2, 21, 23, 27],
        'Lieutenant'  => [12, 14, 17, 29],
        'Captain'     => [3, 8, 19, 25],
        'Major'       => [11, 18, 36],
        'Colonel'     => [22, 38],
        'General'     => [34],
        'Marshal'     => [20]
      }
    },
    {
      'name'      => 'CornerFortress',
      'placement' => {
        'Flag'        => [0],
        'Bomb'        => [2, 9, 11, 14, 17, 20],
        'Spy'         => [16],
        'Scout'       => [18, 21, 24, 25, 31, 34, 36, 39],
        'Miner'       => [4, 7, 19, 26, 28],
        'Sergeant'    => [1, 5, 10, 37],
        'Lieutenant'  => [8, 13, 33, 38],
        'Captain'     => [6, 15, 23, 30],
        'Major'       => [3, 22, 29],
        'Colonel'     => [12, 35],
        'General'     => [32],
        'Marshal'     => [27]
      }
    },
    {
      'name'      => 'ShieldDefense',
      'placement' => {
        'Flag'        => [4],
        'Bomb'        => [3, 5, 14, 19, 27, 35],
        'Spy'         => [12],
        'Scout'       => [6, 13, 24, 28, 31, 33, 34, 38],
        'Miner'       => [0, 2, 8, 11, 16],
        'Sergeant'    => [9, 15, 17, 22],
        'Lieutenant'  => [18, 30, 36, 39],
        'Captain'     => [1, 10, 23, 29],
        'Major'       => [7, 20, 26],
        'Colonel'     => [21, 25],
        'General'     => [37],
        'Marshal'     => [32] 
      }
    },
    {
      'name'      => 'CornerBlitz',
      'placement' => {
        'Flag'        => [0],
        'Bomb'        => [1, 3, 6, 8, 10, 28],
        'Spy'         => [14],
        'Scout'       => [2, 7, 21, 25, 26, 30, 34, 39],
        'Miner'       => [4, 9, 15, 19, 27],
        'Sergeant'    => [5, 12, 16, 38],
        'Lieutenant'  => [17, 20, 31, 35],
        'Captain'     => [18, 22, 33, 36],
        'Major'       => [11, 13, 24],
        'Colonel'     => [23, 37],
        'General'     => [32],
        'Marshal'     => [29]
      }
    },
    {
      'name'      => 'WheelOfDanger',
      'placement' => {
        'Flag'        => [14],
        'Bomb'        => [4, 13, 15, 21, 24, 27],
        'Spy'         => [7],
        'Scout'       => [1, 8, 30, 31, 34, 35, 37, 39],
        'Miner'       => [3, 9, 17, 32, 38],
        'Sergeant'    => [0, 2, 18, 22],
        'Lieutenant'  => [20, 23, 25, 28],
        'Captain'     => [10, 16, 19, 26],
        'Major'       => [5, 29, 33],
        'Colonel'     => [6, 11],
        'General'     => [36],
        'Marshal'     => [12]
      }
    },
    {
      'name'      => 'Blitzkrieg',
      'placement' => {
        'Flag'        => [2],
        'Bomb'        => [1, 3, 12, 17, 24, 29],
        'Spy'         => [18],
        'Scout'       => [0, 6, 11, 13, 23, 25, 27, 30],
        'Miner'       => [5, 15, 21, 22, 39],
        'Sergeant'    => [8, 9, 16, 33],
        'Lieutenant'  => [7, 19, 20, 37],
        'Captain'     => [4, 26, 32, 36],
        'Major'       => [10, 14, 28],
        'Colonel'     => [31, 38],
        'General'     => [35],
        'Marshal'     => [34]
      }
    },
    {
      'name'      => 'EarlyWarning',
      'placement' => {
        'Flag'        => [3],
        'Bomb'        => [2, 4, 11, 13, 21, 35],
        'Spy'         => [22],
        'Scout'       => [0, 16, 29, 30, 33, 34, 36, 39],
        'Miner'       => [5, 9, 14, 18, 28],
        'Sergeant'    => [1, 15, 24, 31],
        'Lieutenant'  => [6, 12, 19, 38],
        'Captain'     => [7, 8, 10, 17],
        'Major'       => [20, 23, 26],
        'Colonel'     => [25, 37],
        'General'     => [27],
        'Marshal'     => [32]
      }
    },
    {
      'name'      => 'ManTheBarricades',
      'placement' => {
        'Flag'        => [0],
        'Bomb'        => [20, 21, 24, 25, 28, 29],
        'Spy'         => [27],
        'Scout'       => [2, 4, 6, 9, 18, 34, 35, 38],
        'Miner'       => [5, 8, 13, 16, 19],
        'Sergeant'    => [3, 10, 11, 15],
        'Lieutenant'  => [14, 22, 31, 37],
        'Captain'     => [12, 17, 32, 39],
        'Major'       => [23, 26, 30],
        'Colonel'     => [7, 36],
        'General'     => [33],
        'Marshal'     => [1]
      }
    }
  ]

  TACTIC_MINI =  {
    'name'      => "MiniTactic",
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

  TACTIC_TEST = {
    'name'      => "TestTactic",
    'placement' => {
      'Sergeant'    =>  [0], 
      'Flag'        =>  [1], 
      'Bomb'        =>  [2], 
      'Spy'         =>  [3], 
      'Scout'       =>  [4], 
      'Lieutenant'  =>  [5], 
      'Captain'     =>  [6], 
      'Major'       =>  [7], 
      'Marshal'     =>  [8],
      'Miner'       =>  [9], 
      'General'     =>  [10], 
      'Colonel'     =>  [11]
    }
  }

  TACTIC_AI_1 = {
    'name'      => 'AiTactic1',
    'placement' => {
      'Bomb'        =>  [1, 10, 14, 16], 
      'Flag'        =>  [0], 
      'Spy'         =>  [3], 
      'Scout'       =>  [11, 15, 17, 19], 
      'Miner'       =>  [13, 18], 
      'Sergeant'    =>  [8], 
      'Lieutenant'  =>  [6], 
      'Captain'     =>  [9], 
      'Major'       =>  [4], 
      'Colonel'     =>  [7, 12],
      'General'     =>  [5], 
      'Marshal'     =>  [2],
    }
  }

  TACTIC_AI_2 = {
    'name'      => 'AiTactic2',
    'placement' => {
      'Bomb'        =>  [1, 7, 10, 17],
      'Flag'        =>  [0],
      'Spy'         =>  [2],
      'Scout'       =>  [13, 14, 15, 18],
      'Miner'       =>  [9, 16],
      'Sergeant'    =>  [12],
      'Lieutenant'  =>  [6],
      'Captain'     =>  [4],
      'Major'       =>  [8],
      'Colonel'     =>  [5, 11],
      'General'     =>  [19],
      'Marshal'     =>  [3],
    }
  }

=begin
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
  |     |     |     |     |     |     |     |     |     |     |     |     |
  |S(4) |F(0) |B(-1)|S(1) |S(2) |L(5) |C(6) |M(7) |M(10)|M(3) |G(9) |C(8) |
  +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
=end

  #***** Methods *****

  def self.make_users(num = USERS_NUM)
    users = Array.new(num) { |i| USER.call(i) }
  end

  def self.make_units
    UNITS
  end

  def self.make_maps(map_name = MAP_CL['name'])
    [MAP_CL, MAP_MINI, MAP_AI]
  end

  def self.make_armies(map_army = ARMY_CL['name'])
    [ARMY_CL, ARMY_MINI, ARMY_AI]
  end

  def self.make_tactic(t = TACTICS_CL[0])
    res = {}
    t['placement'].each_pair do |unit, positions|
      positions.each { |pos| res[pos.to_s] = unit }
    end

    res
  end
end

