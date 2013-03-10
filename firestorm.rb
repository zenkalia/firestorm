require 'curses'
include Curses

require 'pry'

def init_screen
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys
  Curses.start_color
  Curses.init_pair(COLOR_YELLOW, COLOR_YELLOW, COLOR_RED)
  begin
    yield
  ensure
    Curses.close_screen
  end
end

class Cell
  attr_accessor :char

  def initialize(c = nil)
    @char = c || ['H', 'A', 'L'].sample
  end

  def to_s
    @char
  end
end

$map = Array.new(24){ Array.new(60){ Cell.new } }

def blow(dir)
  puts dir
end

def draw
  (0..23).each do |y|
    (0..59).each do |x|
      setpos(y,x)
      attron(color_pair(COLOR_YELLOW)|A_NORMAL) do
        addstr($map[y][x].to_s)
      end
    end
  end
end

init_screen do
  loop do
    draw

    case getch
    when Key::UP then blow 0
    when Key::PPAGE then blow 1
    when Key::RIGHT then blow 2
    when Key::NPAGE then blow 3
    when Key::DOWN then blow 4
    when Key::END then blow 5
    when Key::LEFT then blow 6
    when Key::HOME then blow 7
    when Key::LL then blow 7

    when ?8 then blow 0
    when ?9 then blow 1
    when ?6 then blow 2
    when ?3 then blow 3
    when ?2 then blow 4
    when ?1 then blow 5
    when ?4 then blow 6
    when ?7 then blow 7

    when ?k then blow 0
    when ?u then blow 1
    when ?l then blow 2
    when ?n then blow 3
    when ?j then blow 4
    when ?b then blow 5
    when ?h then blow 6
    when ?y then blow 7

    when ?p then close_screen; binding.pry

    when ?q then break
    end
  end
end

