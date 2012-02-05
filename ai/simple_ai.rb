#coding: utf-8

def clone(obj)
  Marshal.load Marshal.dump(obj)
end

module SimpleAi
  private
  
  def parse_game(game)
    @is_turn = game['isTurn']

    @army_units = game['army']['units']
    @map = game['map']

    @my_state = game['state']['pl1']
    init_opp_state(game['state']['pl2'])
  end

  def init_opp_state(opp_positions)
    a = @army_units.keys.map { |k| @army_units[k]['count'] }
    all_units_count = a.reduce(:+)
    h = {}
    @army_units.each_pair do |k, v|
      h[k] = v['count'].to_f / all_units_count
    end

    @opp_state = {}
    opp_positions.each { |pos| @opp_state[pos] = clone(h) }
  end
  
  def make_move
    # r = case @moves_counter
    # when 1
    #   [14, 44]
    # when 2
    #   [15, 45]
    # else
    #   [18, 48]
    # end

    # { cmd: 'makeMove', posFrom: r[0], posTo: r[1] }
    {}
  end

  def process_move(resp)
  end

  def process_opponent_move(resp)
    p resp
  end

  #--------- Moves ---------

  def forward
  end

  def backward
  end

  def left
  end

  def right
  end
end
