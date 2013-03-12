
require 'curses'
require 'yaml'
include Curses


  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys

loop do
  a = getch
  puts a
  puts a.to_i
end
