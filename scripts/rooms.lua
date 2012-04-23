get_room = get_thing

function add_room(id, name, description)
   local room = {id=id, name=name, long_desc=(description or 'A non-descript room.'), contents={}, types={'room'}}
   if id then
      add_thing(id, room)
   else
      id = create_thing('room', room)
      room.id = id
      room.name = id
   end
   DEBUG('Added room \'' .. id .. '\'')
   return room
end
