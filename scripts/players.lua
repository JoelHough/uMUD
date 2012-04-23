-- In main.lua:
-- local player = add_player( name , {types = {'muderator'} } )

function add_player(id, data)
   data.name = id
   data.id = id
   -- Inventory?
   data.inventory = {'guitar pick', 'lightsaber'}
   if add_thing(id, data) then
      DEBUG('Added player \'' .. id .. '\'')
      return data
   end
end

function get_player(id)
   return get_thing(id)
end

function open_inventory(id)
	local player = get_thing(id)
	-- Start printing out things
	-- Tables start indexing @ *1*
	player_text(player, 'Your inventory contains: ')
	for i,k in ipairs(player.inventory) do
		player_text(player, '> ' .. i .. '  ' .. k)
	end
end
