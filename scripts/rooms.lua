require'types'
require'containers'

local rooms={void={name="The Void", contents={}, long_desc='A formless, black emptiness.', types={'room'}}}

function get_room(id)
   return rooms[id]
end

add_atoms{room={'noun', 'container'}}
