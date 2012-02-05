#coding: utf-8

module Printer
  CELL_H = 5
  CELL_W = 2

  INDENT_SIZE = 2

  private

  def draw_game_state
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
              [@opp_positions, -> { "O_#{pos}" }]
            else
              [@my_positions, -> { @my_state[pos][0, CELL_H] }]
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

  #----- My implementation of the pretty printer for hashes -----

  def pp_hash(h, lim_depth = 0)
    draw = ->(hh, d) do
      r = "{\n"
      hh.each_pair do |k, v|
        r += ' ' * (d + 1) * INDENT_SIZE + k.to_s + ' => '
        if v.instance_of?(Hash) && lim_depth != 0 && d < lim_depth - 1
          r += draw.(v, d + 1)
        else
          r += v.to_s + "\n"
        end
      end
      r + ' ' * d * INDENT_SIZE + "}\n"
    end

    draw.(h, 0)
  end
end
