#coding: utf-8

module Painter
  CELL_H = 5
  CELL_W = 2

  def draw_game_state
    my_positions = @my_state.keys.map { |el| el.to_i }
    res = ''

    (@map['height'] - 1).downto(0) do |i|
      line = ''
      @map['width'].times { |j| line += '+' + '-' * CELL_H }
      line += "+\n"

      CELL_W.times do |k|
        @map['width'].times do |j|
          line += '|'
          pos = i * @map['width'] + j
          a, c =
            if k == 0
              [@opp_state, -> { "O_#{pos}" }]
            else
              [my_positions, -> { @my_state[pos.to_s][0, CELL_H] }]
            end
          if @map['obst'].include?(pos)
            line += 'X' * CELL_H
          elsif a.include?(pos)
            s = c.()
            line += s + ' ' * (CELL_H - s.length)
          else
            line += ' ' * CELL_H
          end
        end
        line += "|\n"
      end

      if i == 0
        @map['width'].times { |j| line += '+' + '-' * CELL_H }
        line += "+\n"
      end

      res += line
    end

    res
  end

  def draw_statistics

  end
end
