require 'curses'
include Curses

def init_screen
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys
  begin
    yield
  ensure
    Curses.close_screen
  end
end

def blow(dir)
  puts dir
end

init_screen do
  loop do
    #display shit

    case Curses.getch
    when Curses::Key::UP then blow 0
    when Curses::Key::PPAGE then blow 1
    when Curses::Key::RIGHT then blow 2
    when Curses::Key::NPAGE then blow 3
    when Curses::Key::DOWN then blow 4
    when Curses::Key::END then blow 5
    when Curses::Key::LEFT then blow 6
    when Curses::Key::HOME then blow 7
    when Curses::Key::LL then blow 7

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
    when ?q then break
    end
  end
end

