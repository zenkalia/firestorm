require 'curses'
include Curses

require 'pry'

def init_screen
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys
  Curses.start_color
  Curses.init_pair(COLOR_YELLOW, COLOR_YELLOW, COLOR_RED)
  Curses.init_pair(COLOR_RED, COLOR_RED, COLOR_YELLOW)
  Curses.init_pair(COLOR_WHITE, COLOR_WHITE, COLOR_BLACK)
  Curses.init_pair(COLOR_BLUE, COLOR_BLACK, COLOR_BLUE)
  Curses.init_pair(COLOR_GREEN, COLOR_BLACK, COLOR_GREEN)
  begin
    yield
  ensure
    Curses.close_screen
  end
end

class Cell
  attr_accessor :char
  attr_accessor :lit

  def buildings
    ['H','A','R','N','T','#']
  end

  def grass
    ['~','`',"'",',']
  end

  def degrade
    return if dead?
    deg = {
      'H' => ['h','n','l'],
      'A' => ['I','h'],
      'R' => ['H','h', 'K'],
      'K' => ['h','n','l'],
      'N' => ['l','\\'],
      'T' => ['l'],
      '#' => ['H','K'],
      'h' => ['n','l','i'],
      'n' => ['i','v'],
      'I' => ['i'],
      'l' => ['i'],
      '\\' => ['i','v'],
      'i' => [],
      'v' => []
    }
    @char = deg[@char].sample
  end

  def dead?
    @char.nil?
  end

  def initialize(c = nil)
    @char = c || buildings.sample
    @lit = false
  end

  def tick
    @lit = false if dead?
    degrade if @lit and rand(2).zero?
  end

  def to_s
    if @char == :grass
      return grass.sample
    end
    @char || '.'
  end

  def color
    return COLOR_GREEN if @char == :grass
    return COLOR_BLUE if @char == :water
    COLOR_WHITE
  end
end

def each_cell
  (0..23).each do |y|
    (0..59).each do |x|
      yield(x,y)
    end
  end
end

$map = Array.new(24){ Array.new(60){ Cell.new } }
$wind_variance = 5

def blow(dir)
  each_cell do |x,y|
    $map[y][x].tick
  end
  if rand(100) < $wind_variance
    dir += (rand(2).zero? ? 1 : -1)
  end
  dir %= 8
  $map[rand(24)][rand(60)].lit = true
  #puts dir
end

$show_fire = true
def toggle_view
  $show_fire = !$show_fire
end

def draw
  each_cell do |x,y|
    c = $map[y][x]
    setpos(y,x)
    if $show_fire and c.lit
      attron(color_pair(COLOR_YELLOW)|A_NORMAL) do
        addstr(c.to_s)
      end
    else
      attron(color_pair(c.color)|A_NORMAL) do
        addstr(c.to_s)
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

    when ' ' then toggle_view

    when ?p then close_screen; binding.pry

    when ?q then break
    end
  end
end

