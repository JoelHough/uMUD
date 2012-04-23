-- In main.lua:
-- local player = add_player( name , {types = {'muderator'} } )

function add_player(id, data)
   data.name = id
   data.id = id
   -- Inventory?
   data.itemsCount = 2;
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

-- NOTE:
-- If adding, say, money --> Will need to check current balance and add to!....
function add_to_inventory(id, item)
	local player = get_player(id)
	
	table.insert(player.inventory, item.id)


	--player.itemsCount = player.itemsCount + 1
	local player = get_thing(id)
	-- IF item is 'carryable'
	-- if.... do....
	--player.inventory[data.itemsCount] = item
	player_text(player, 'You pick up a ' .. item.name)
end





	
