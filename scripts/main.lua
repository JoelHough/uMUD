require'log'
require'parser'
require'binder'
require'types'
require'functions'

function got_player_text(name, text)
   -- Got text from player's client
   DEBUG(name .. '->' .. text)

   local ast, msg = parse(text)
   if not ast then
      send_player_text(name, msg)
      return nil
   end
         
   for _, sentence in ipairs(match.sentences) do
      for _, command in ipairs(sentence.commands) do
         local verb = command.verb
         local subject, object
         if command.phrase1 then subject = get_objects_from_phrase(command.phrase1) end
         if command.phrase2 then object = get_objects_from_phrase(command.phrase2) end
         DEBUG(locals('verb', 'subject', 'object'))
         get_function(verb, subject, object)(things[name], collider[verb], subject and collider[subject])
      end
   end
end

function send_player_text(name, text)
   -- Server send
   DEBUG(name .. '<-' .. text)
end