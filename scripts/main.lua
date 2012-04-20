require'log'
function server_send(name, text)
    send_player_text(name, text)
end

require'messaging'
require'types'
require'functions'
require'parser'
require'binder'
require'things'
require'players'
require'muderators'
require'rooms'
require'portals'

function say(text)
   return got_player_text('God', text)
end

--this function is called by server.cpp when player sends a message.
function got_player_text(name, text)
   -- Got text from player's client
   -- some test code -C
   io.write("debug from lua recieved name: ", name, ", and message: ", text, " -main.lua L:24 " , "\n")
   -- end test code
   DEBUG(name .. '->' .. text)
   q = "Yo! " .. name .. "! lua is sending you a message bitch!"
   send_player_text(name, q)


end

-- this function calls a method in server.cpp to send a message out on the socket connected to the player named by 'name'
function send_player_text(name, text)
   --Server send
   --some test code -C
   c = from_lua(name, text)
   io.write("from_lua returned '", c, "' -main.lua L:51","\n")
   --end test code
   DEBUG(name .. '<-' .. text)
end
