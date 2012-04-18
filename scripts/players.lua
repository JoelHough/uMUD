require'things'
require'creatures'
require'rooms'

function add_player(id, data)
   if add_thing(id, data) then
      DEBUG('Added player \'' .. id .. '\'')
      add_atoms{[id:lower()]='pronoun'}
   end
end

add_atoms{player='creature'}
add_functions{
   ['player look room'] = function (player, verb, room_phrase) print(player.container.long_desc) end,
   ['player say-to string-type thing'] = function(player, verb, msg, thing)
      player_text(player, 'You say "' .. msg.string .. '" to ' .. thing.name .. '.')
      witness_text(player, player.name .. ' says "' .. msg.string .. '" to ' .. thing.name .. '.')
   end
            }