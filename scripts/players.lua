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
add_function{
   ['player look room'] = function (player, verb, room_phrase) print(player.container.long_desc) end
            }