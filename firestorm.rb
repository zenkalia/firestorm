require 'curses'
require 'yaml'
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

  def buildings
    ['H','A','R','N','T','#']
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
    degrade if @lit and coin_flip
  end

  def to_s
    @char || ' '
  end

  def lit
    @lit
  end

  def light
    @lit = true unless dead?
  end

  def color
    COLOR_WHITE
  end
end

class Wavey < Cell
  def to_s
    return ' ' if dead?
    ['~','`',"'",','].sample
  end
end

class Water < Wavey
  def color
    return COLOR_BLUE
  end

  def light
  end
end

class Grass < Wavey
  def color
    dead? ? COLOR_WHITE : COLOR_GREEN
  end
end

def each_cell
  (0..23).each do |y|
    (0..59).each do |x|
      yield(x,y)
    end
  end
end

def coin_flip
  rand(2).zero?
end

def make_map(rivers = 2, parks = 2, barrels = false)
  rivers.times do
    start_x = last_x = rand(60)
    last_width = 3
    (0..23).each do |y|
      begin
        width = rand(3)+2
        this_x = last_x + (coin_flip ? rand(last_width) : -1 * rand(width) )
      end while (this_x < 0 or this_x + width > 59)
      (this_x..this_x+width).each do |x|
        $map[y][x] = Water.new
      end
      last_x = this_x
      last_width = width
    end
  end

  parks.times do
    park_size = rand(20)+20
    park_cells = []
    begin
      start_y = rand(24)
      start_x = rand(60)
    end while $map[start_y][start_x].class != Cell

    park_cells << [start_x, start_y]

    while park_cells.count < park_size
      begin
        x,y = park_cells.sample
        if coin_flip
          x += coin_flip ? 1 : -1
        else
          y += coin_flip ? 1 : -1
        end
      end while park_cells.index([x,y]) or x < 0 or y < 0 or x >= 60 or y >= 24 or $map[y][x].class != Cell
      park_cells << [x, y]
    end
    park_cells.each do |x,y|
      $map[y][x] = Grass.new
    end
  end
end

t = File.open('./data/dante.txt', 'r')
$dante = t.read
$dante.gsub!(/\s+/, '-')
$dante_position = rand($dante.length)
t.close
t = File.open('./data/names.yml','r')
$names = YAML::load(t)
t.close

$map = Array.new(24){ Array.new(60){ Cell.new } }
make_map
$wind_variance = 5

def blow(dir)
  each_cell do |x,y|
    $map[y][x].tick
  end
  if rand(100) < $wind_variance
    dir += (coin_flip ? 1 : -1)
  end
  dir %= 8
  spread_to = []
  each_cell do |x,y|
    c = $map[y][x]
    if c.lit
      case dir
      when 0 then y -= 1
      when 1 then y -= 1; x += 1
      when 2 then         x += 1
      when 3 then y += 1; x += 1
      when 4 then y += 1
      when 5 then y += 1; x -= 1
      when 6 then         x -= 1
      when 7 then y -= 1; x -= 1
      end
      spread_to << [x,y] if y >= 0 and x >= 0 and y < 24 and x < 60
    end
  end

  spread_to.each do |x,y|
    $map[y][x].light
  end
  $map[rand(24)][rand(60)].light
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
        addstr($dante[$dante_position])
        $dante_position += 1
        $dante_position %= $dante.length
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

