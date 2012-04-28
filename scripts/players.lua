-- In main.lua:
-- local player = add_player( name , {types = {'muderator'} } )

function add_player(id, data)
   data.name = id
   data.id = id

   if add_thing(id, data) then
      DEBUG('Added player \'' .. id .. '\'')
      --return data
   end

   -- Inventory
   DEBUG('<><><> SETTING UP INVENTORY...')
   local player = get_player(id)
   player.inventory = {'lightsaber', 'guitar pick', '10 coins'}

   return data

end

function get_player(id)
   return get_thing(id)
end


-- <Inventory Item Hierarchy>
--    (IMPLEMENTED)         (NOT IMPLEMENTED)
--   item (carryable)    object (not-carryable)
--     ^                    ^
--	    thing

-- add_atoms{ item='thing', [{'rock', 'coin'}] = 'item'}


function open_inventory(id)
	-- Start printing out things
	local player = get_player(id)
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

	-- Check if dealing with a currency item
	if item.name == 'coin' then
		--player_text(player, 'You\'re handling money, aren\'t you?')
		up_monies(id)
	else
		-- Put the item in the player's inventory-table
		table.insert(player.inventory, item.name)
		--do_to('put-in', contents, create_thing(item, {types={item}}))
	end

	-- Action Messages
	player_text(player, 'You pick up a ' .. item.name)
	witness_text(player, 'Picks ' .. item.name .. ' up from the ground.')
end

-- drop_from_inventory(player.name, item)
-- ***<Currently DOES NOT WORK>*** --> Does not strictly follow the LUA object hierarchy,
-- so it needs either (1) a personal binder, or (2) to use the containers.contents + move_contents (ran out of time)
function drop_from_inventory(id, item)

	--player_text(player, '<DEBUG>: In drop_from_inventory')

	local player = get_player(id)
	local area_around = M('container', player)

	-- Take out of inventory
	--local index = player.inventory[item.id]
	local index = player.contents[item.id]
	--table.remove(player.inventory, index)
	table.remove(player.contents, index)

	-- Put item into the surrounding area <Does Not work!>....
	DEBUG('area_around ~ <' .. area_around.name .. '>')
	table.insert(area_around.contents, item)

	-- Message Action!
	player_text(player, 'You drop ' .. item.name .. ' from your inventory.')
	witness_text(player, 'Drops ' .. item.name .. ' onto the ground.')

end

-- Adjust currency when picked up
--	Increment: WORKS
--	DECREMENT: To-Do
function up_monies(id)
	local player = get_player(id)
	-- Get the current total currency of the player
		-- Loop through I - find key that contains '$'...
		-- convert digits to numbers, +1, restore...
	local pattern = "coins"
	--for i,k in ipairs(player.inventory) do
	for i,k in ipairs(player.inventory) do
		local find1, find2 = string.find(k, pattern)
		-- <DEBUG>
		player_text(player, 'i = ' .. i .. ', k = ' .. k)
		if find1 then
			-- Grab the integer representing the amount
			local space = string.find(k, ' ')
			local amount = string.sub(k, 1, space-1)
			-- Increment it
			local newAmount = amount + 1
			
			--player_text(player, 'Amt = <' .. amount .. '>')
			--player_text(player, 'NewAmt = <' .. newAmount .. '>')

			-- Replace current inventory amount
			local balance = newAmount .. ' coins'
			table.insert(player.inventory, balance)
			local oldBalance = player.inventory[i]
			-- <DEBUG>
			--player_text(player, 'Old Balance = <' .. oldBalance .. '>')
	
			
			table.remove(player.inventory, i)

			return
		
		end
			--player_text(player, 'find1 for \"' .. k .. '\" is ' .. find1)	end

	end
end




	
