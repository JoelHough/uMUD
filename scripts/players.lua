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


-- <Inventory Item Hierarchy>
--
--   item (carryable)    object (not-carryable)
--     ^                    ^
--	    thing

-- add_atoms{ item='thing', [{'rock', 'coin'}] = 'item'}


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
	local original_container = M('container', player)	

	-- Put the item in the player's inventory-table
	table.insert(player.inventory, item.id)
	player_text(player, 'You pick up a ' .. item.name)
	witness_text(player, 'Picks ' .. item.name .. ' up from the ground.')
end

-- drop_from_inventory(player.name, item)
function drop_from_inventory(id, item)
	local player = get_player(id)
	local area_around = M('container', player)

	-- Take out of inventory
	local index = player.inventory[item.id]
	table.remove(player.inventory, index)

	-- Put item into the surrounding area <Does Not work!>....
	DEBUG('area_around ~ <' .. area_around.name .. '>')
	table.insert(area_around, item.id)

	-- <Message Action!>
	player_text(player, 'You drop ' .. item.name .. ' from your inventory.')
	witness_text(player, 'Drops ' .. item.name .. ' onto the ground.')

end


	
