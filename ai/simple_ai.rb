#coding: utf-8

def clone(obj)
  Marshal.load Marshal.dump(obj)
end

module SimpleAi
  private

  #--------- Main methods ---------

  def parse_game(game)
    @is_turn = game['isTurn']

    @army_units = game['army']['units']

    @map = game['map']
    @map['size'] = @map['width'] * @map['height']
    init_move_directions

    @my_state = {}
    game['state']['pl1'].each_pair { |k, v| @my_state[k.to_i] = v }
    init_opp_state(game['state']['pl2'])

    @my_positions = @my_state.keys.sort
    @opp_positions = @opp_state.keys.sort
  end

  def make_move
    pos_from, pos_to = make_random_move
    if @opp_positions.include?(pos_to)          # It will be duel
      @my_attacker = @my_state.delete(pos_from)
      @last_pos_to = pos_to
    else
      @my_state[pos_to] = @my_state.delete(pos_from)
    end
    @my_positions = @my_state.keys.sort

    cmd_make_move(pos_from, pos_to)
  end

  def process_duel(resp)
    duel = resp['duel']
    return if duel.nil? || duel['result'] == 'loss'
    if duel['result'] == 'win'
      @my_state[@last_pos_to] = @my_attacker
      @my_positions = @my_state.keys.sort
    end

    @opp_state.delete(@last_pos_to)
    @opp_positions = @opp_state.keys.sort
  end

  def process_opponent_move(resp)
    pos_from, pos_to = resp['posFrom'], resp['posTo']
    duel = resp['duel']

    u = @opp_state.delete(pos_from)

    if duel
      case duel['result']
      when 'win'
        # That's ok
      when 'loss'
        @my_state.delete(pos_to)
        @opp_state[pos_to] = u
        @my_positions = @my_state.keys.sort
      when 'draw'
        @my_state.delete(pos_to)
        @my_positions = @my_state.keys.sort
      end
    else
      @opp_state[pos_to] = u
    end

    @opp_positions = @opp_state.keys.sort
  end

  #--------- Extra methods ---------

  def init_move_directions
    @directions = [:forward, :left, :right, :backward]  # Order is important!
    @move_directions = {
      forward:  (->(pos) { pos + @map['width'] }),
      left:     (->(pos) { pos - 1 }),
      right:    (->(pos) { pos + 1 }),
      backward: (->(pos) { pos - @map['width'] })
    }
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
  
  def make_random_move
    active_positions = @my_positions.select { |p| @army_units[@my_state[p]]['moveLength'] > 0 }
    a =  active_positions.map { |p| [p, @directions.select { |d| available?(p, d) }] }
    a.select! { |el| !el[1].empty? }
    p = a[rand(0...a.size)]
    pos_from = p[0]

    [pos_from, @move_directions[p[1][0]].call(pos_from)]
  end

  #--------- Helpers ---------

  def border?(pos, direction)
    (direction == :forward && (pos / @map['width']) == @map['height'] - 1) ||
    (direction == :left && pos % @map['width'] == 0) ||
    (direction == :right && (pos + 1) % @map['width'] == 0) ||
    (direction == :backward && (pos / @map['width'] == 0))
  end

  def available?(pos, direction)
    new_pos = @move_directions[direction].call(pos)

    !border?(pos, direction) &&
    !@map['obst'].include?(new_pos) &&
    !@my_positions.include?(new_pos)
  end

  def opponent?(pos, direction)
  end
end
