require'log'
log_level = 'ERROR'
function send_player_text(name, text)
   -- Server send
   TEST(name .. '<-' .. text)
   end
function server_send(name, text)
    send_player_text(name, text)
end
require'umud'

function say(text)
   return got_player_text('God', text)
end

--this function is called by server.cpp when player sends a message.
function got_player_text(name, text)
   -- Got text from player's client
   -- some test code -C
   TEST(name .. '->' .. text)
   io.write("debug from lua recieved name: ", name, ", and message: ", text, " -main.lua L:24 " , "\n")
   -- end test code
   q = "Yo! " .. name .. "! lua is sending you a message bitch!"

   local player = get_player(name)
   if not player then
      ERROR('Command from invalid player \'' .. name .. '\'')
      return nil
   end
   local ast, msg = parse(text)
   if not ast then
      send_player_text(name, msg)
      return nil
   end

   for _, sentence in ipairs(ast.sentences) do
      for _, command in ipairs(sentence.commands) do
         bind_and_execute(player, command)
      end
   end



end

-- this function calls a method in server.cpp to send a message out on the socket connected to the player named by 'name'
   --Server send
   --some test code -C
   c = from_lua(name, text)
   io.write("from_lua returned '", c, "' -main.lua L:51","\n")
   --end test code
