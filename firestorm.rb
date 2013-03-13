#!/usr/bin/ruby

require 'curses'
require 'yaml'
include Curses

Dir.chdir File.dirname(__FILE__)

require 'pry' unless ARGV.empty?

class Array
  def sample
    self[rand(self.count)]
  end
end

def init_screen
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys
  Curses.start_color
  Curses.curs_set(0)
  Curses.init_pair(COLOR_YELLOW, COLOR_YELLOW, COLOR_RED)
  Curses.init_pair(COLOR_RED, COLOR_RED, COLOR_BLACK)
  Curses.init_pair(COLOR_CYAN, COLOR_BLUE, COLOR_BLACK)
  Curses.init_pair(COLOR_WHITE, COLOR_WHITE, COLOR_BLACK)
  Curses.init_pair(COLOR_BLUE, COLOR_BLACK, COLOR_BLUE)
  Curses.init_pair(COLOR_GREEN, COLOR_BLACK, COLOR_GREEN)
  Curses.init_pair(COLOR_MAGENTA, COLOR_MAGENTA, COLOR_CYAN)
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

  def lit?
    @lit
  end

  def light
    @lit = true unless dead?
  end

  def color
    COLOR_WHITE
  end
end

class Barrel < Cell
  def initialize(x,y)
    super nil
    @x = x
    @y = y
  end
  def color
    COLOR_RED
  end
  def to_s
    return ' ' if dead?
    'O'
  end
  def degrade
    return if dead?
    d = 2 + rand(3) + rand(2)
    each_cell do |x,y|
      $map[y][x].light if man_distance(@x,@y,x,y) < d.to_f
    end

    @char = nil
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
    COLOR_BLUE
  end

  def light
  end
end

class Grass < Wavey
  def color
    dead? ? COLOR_WHITE : COLOR_GREEN
  end

  def degrade
    return if dead?
    @char = nil
  end
end

class Person
  attr_accessor :alive, :y, :x

  @@all = []
  def self.all
    @@all
  end
  def initialize(x,y)
    @alive = true
    @x = x
    @y = y
    @@all << self
  end
  def dead?
    !@alive
  end
  def tick
    if $map[@y][@x].lit?
      @alive = false
    end
  end
  def self.destroy_all
    @@all = Array.new
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

def man_distance(x1,y1,x2,y2)
  dx = (x2-x1).abs
  dy = (y2-y1).abs
  [dx,dy].min * 1.707 + (dx-dy).abs
end

def make_map(rivers = 2, parks = 2, river_barrels = false, barrels = 0, towers = 0)
  rivers.times do
    start_x = last_x = rand(60)
    last_width = 3
    (0..23).each do |y|
      tries = 0
      begin
        width = rand(3)+2
        this_x = last_x + (coin_flip ? rand(last_width) : -1 * rand(width) )
        tries += 1
        break if tries > 1000
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

    tries = 0
    while park_cells.count < park_size
      begin
        x,y = park_cells.sample
        if coin_flip
          x += coin_flip ? 1 : -1
        else
          y += coin_flip ? 1 : -1
        end
        tries += 1
        break if tries > 1000
      end while park_cells.index([x,y]) or x < 0 or y < 0 or x >= 60 or y >= 24 or $map[y][x].class != Cell
      park_cells << [x, y]
    end
    park_cells.each do |x,y|
      $map[y][x] = Grass.new
    end
  end

  barrels.times do
    begin
      x = rand(60)
      y = rand(24)
    end until $map[y][x].class == Cell
    $map[y][x] = Barrel.new(x,y)
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
t = File.open('./data/levels.yml','r')
$levels = YAML::load(t)
t.close
$level = 0

def blow(dir)
  each_cell do |x,y|
    $map[y][x].tick
  end
  spread_to = []
  each_cell do |x,y|
    c = $map[y][x]
    if c.lit?
      copy_dir = dir
      if rand(100) < $wind_variance
        copy_dir += (coin_flip ? 1 : -1)
      end
      copy_dir %= 8
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
  begin
    x = rand(60)
    y = rand(24)
  end until Person.all.select{|a| a.x == x and a.y == y}.count == 0 and $map[y][x].class != Water
  $map[y][x].light
  $celebs.each { |c| c.tick }
  $lovers.each { |c| c.tick }
  $turns -= 1
end

$show_fire = true
def toggle_view
  $show_fire = !$show_fire
end

def draw
  each_cell do |x,y|
    c = $map[y][x]
    setpos(y,x)
    if $show_fire and c.lit?
      attron(color_pair(COLOR_YELLOW)|A_NORMAL) do
        addstr($dante[$dante_position,1].to_s)
        $dante_position += 1
        $dante_position %= $dante.length
      end
    else
      attron(color_pair(c.color)|A_NORMAL) do
        addstr(c.to_s)
      end
    end
  end
  if $show_fire
    $celebs.each do |c|
      unless c.dead?
        setpos(c.y,c.x)
        attron(color_pair(COLOR_MAGENTA)|A_NORMAL) do
          addstr('*')
        end
      end
    end
    $lovers.each do |c|
      unless c.dead?
        setpos(c.y,c.x)
        attron(color_pair(COLOR_MAGENTA)|A_NORMAL) do
          addstr('@')
        end
      end
    end
  end
end

def draw_sidebar
  setpos(1,63)
  addstr('Firestorm City')
  setpos(2,63)
  addstr('==============')

  draw_box(7, 18, 4, 61)
  setpos(5,62)
  addstr("Things remaining:")
  setpos(7, 66)
  addstr("Turns:   ")
  setpos(7, 66)
  addstr("Turns: #{$turns}")
  setpos(8, 64)
  addstr("Loved ones: #{$lovers.select{|a|a.alive}.count}")
  setpos(9, 67)
  addstr("VIPs: #{$celebs.select{|a|a.alive}.count}")
  setpos(10, 63)
  addstr("Innocents: TONS")

  draw_box(8,18,11, 61)
  setpos(12,66)
  addstr('Controls:')
  setpos(13,62)
  addstr('Swap view: Space')
  setpos(14,62)
  addstr('Wind:')
  setpos(15,62)
  addstr('Arrows, PgUp,')
  setpos(16,62)
  addstr('PgDown, Home, End')
  setpos(17,66)
  addstr('-OR-')
  setpos(18,62)
  addstr('hjklyubn')

  draw_box(4,18,19,61)
  setpos(20,62)
  addstr('Score:')
  setpos(21,64)
  addstr('1000000')
  setpos(22,62)
  addstr("Level: #{($level+1).to_s}")
end

def draw_box(height, width, top, left)
  (top..top+height).each do |y|
    setpos(y,left)
    addstr('|')
    setpos(y,left+width)
    addstr('|')
  end
  (left..left+width).each do |x|
    setpos(top,x)
    addstr('-')
    setpos(top+height,x)
    addstr('-')
  end
end

def set_up_level
  $map = Array.new(24){ Array.new(60){ Cell.new } }
  l = $levels[$level]
  make_map(l['rivers'], l['parks'], l['river_barrels'], l['barrels'], l['towers'])
  Person.destroy_all
  $celebs = []
  $lovers = []
  begin
    y = rand(24)
    x = rand(60)
    if $map[y][x].class != Water and Person.all.select{|a| a.x == x and a.y == y}.count == 0
      $celebs << Person.new(x,y)
    end
  end while $celebs.count < 3
  begin
    y = rand(24)
    x = rand(60)
    if $map[y][x].class != Water and Person.all.select{|a| a.x == x and a.y == y}.count == 0
      $lovers << Person.new(x,y)
    end
  end while $lovers.count < 3
  $wind_variance = l['wind']
  $turns = 40
  blow 0
end

set_up_level
init_screen do
  loop do
    if Person.all.select{|a|a.alive}.count == 0
      #game_over
      break
    end
    if $turns == 0
      $level += 1
      #show_points
      if $level == $levels.count
        #show_ending
        break
      end
      set_up_level
    end
    draw
    draw_sidebar

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
    when 32 then toggle_view

    when ?p then close_screen; binding.pry

    when ?q then break
    end
  end
end

