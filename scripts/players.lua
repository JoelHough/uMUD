function add_player(id, data)
   data.name = id
   data.id = id
   if add_thing(id, data) then
      DEBUG('Added player \'' .. id .. '\'')
      return data
   end
end

function get_player(id)
   return get_thing(id)
end
