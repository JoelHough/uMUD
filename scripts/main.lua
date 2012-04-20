--require'log'
function server_send(name, text)
    send_player_text(name, text)
end

--require'messaging'
--require'types'
--require'functions'
--require'parser'
--require'binder'
--require'things'
--require'players'
--require'muderators'
--require'rooms'
--require'portals'

function say(text)
   return got_player_text('God', text)
end

function got_player_text(name, text)
   -- Got text from player's client
   -- some test code -C
   io.write("debug from lua recieved name: ", name, ", and message: ", text, " -main.lua L:24 " , "\n")
   -- end test code
   --DEBUG(name .. '->' .. text)
   q = "Yo! " .. name .. "! lua is sending you a message bitch!"
   send_player_text(name, q)


end

function send_player_text(name, text)
   -- Server send
   --some test code -C
   c = from_lua(name, text)
   io.write("from_lua returned '", c, "' -main.lua L:51","\n")
   --end test code
   --DEBUG(name .. '<-' .. text)
end
