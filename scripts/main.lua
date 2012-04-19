require'log'
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
   DEBUG(name .. '->' .. text)

   local player = get_thing(name)
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

function send_player_text(name, text)
   -- Server send
   DEBUG(name .. '<-' .. text)
end
