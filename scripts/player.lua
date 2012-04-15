require'things'
require'creatures'

add_atoms{player='creature'}

function add_player(id, data)
   if add_thing(id, data) then
      DEBUG('Added player \'' .. id .. '\'')
      add_atoms{[id:lower()]='pronoun'}
   end
end