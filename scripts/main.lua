package.path = package.path .. ";../scripts/?.lua"
require'log'
log_level = 'DEBUG'
require'umud'

function say(text)
   return got_player_text('God', text)
end

function new_player(name)
   local player = add_player(name, {types={'muderator'}})
   F{'connect', player}(player)
end

--this function is called by server.cpp when player sends a message.
function got_player_text(name, text)
   text = trim(strip_extended(text))

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
      server_send(name, msg)
      return nil
   end

   for _, sentence in ipairs(ast.sentences) do
      for _, command in ipairs(sentence.commands) do
         bind_and_execute(player, command)
      end
   end



end




