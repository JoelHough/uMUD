--********************************************************************
--Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
--*********************************************************************

require'base'

-- Protip: If you are accessing a field on a thing, you are probably doing it wrong.
-- Use the function hierarchy. F{}()

-- Things and stuff about things
require'things'

-- Players
add_atoms{muderator='player',
          player='creature',
          creature='thing',
          thing='noun',
          noun='word',
          disconnect='verb'
         }

require'players'
local god = get_thing('God') or add_player('God', {types={'muderator'}})
local force = get_thing('A mysterious force') or add_player('A mysterious force', {types={'muderator'}})
local function force_do(command)
   local ast, msg = parse_command(command)
   printTable(ast, DEBUG)
   return bind_and_execute(force, ast)
end

require'things'
add_atoms{eval='verb', hotpatch='verb'}
add_functions{
   ['connect player'] = function(player)
      force_do('whisk ' .. player.id .. ' to The Void')
   end,
   ['everything'] = things,
   ['detail thing'] = function(thing) return thing.long_desc or 'It is very non-descript.' end,
   ['name thing'] = function(thing) return thing.name or 'nameless thing' end,
   -- *************************
   ['name rock'] = function(rock) return 'rock' end,	
   ['name coin'] = function(coin) return 'coin' end,
   -- *************************

   ['definite thing'] = function(thing) return 'the ' .. M('name', thing) end,
   ['indefinite thing'] = function(thing) return 'a ' .. M('name', thing) end, -- TODO 'an'

   -- *************************
   ['indefinite item'] = function(item) return 'a ' .. M('name', item) end,
   -- *************************
   ['definite player'] = function(player) return M('name', player) end,
   ['indefinite player'] = function(player) return M('name', player) end,
   ['player disconnect'] = function(player)
      witness_text(player, M('indefinite', player) .. ' vanishes!')
      remove_content(player)
      things[player.id] = nil
      server_disconnect_player(player.id)
   end,
   ['subject-bind-search eval'] = 'none',
   ['muderator hotpatch'] = function(muderator)
      player_text(muderator, "You begin reciting the arcane rite from the Book of Creation.  You feel the power of the universe soaking into you.")
      witness_text(muderator, M('indefinite', muderator) .. ' begins chanting in an ancient, powerful tongue.  A blue glow swells and envelopes them.')
      if os.execute('git pull') ~= 0 then
         player_text(muderator, "*CRACK*\nThe energy flees, leaving you drained.  Maybe the moon is in the wrong phase?")
         witness_text(muderator, "You here a tremendous *CRACK* as the blue glow rushes from " .. M('indefinite', muderator) .. '.  You get the feeling that whatever was happening did not go well.')
      else
         dofile'../scripts/hotpatch.lua'
         player_text(muderator, "*FWOOSH*\nThe energy flies from you, altering the very fabric of time and space!")
         witness_text(muderator, "You here a tremendous *FWOOSH* as the blue glow rushes from " .. M('indefinite', muderator) .. ', washing over you.  You get the feeling that whatever was happening, the world will never be the same.')
      end
   end,
   ['muderator eval string-type'] = function(muderator, cmd)
      player_text(muderator, "Your words run deep.")
      loadstring(cmd.string)()
   end
             }

-- Being in things, including rooms
require'containers'
require'rooms'
add_atoms{room={'container', 'thing'}, [{'look', 'whisk', 'rename', 'describe'}]='verb', [{'to', 'as'}]='preposition'}

function witness_change(muderator)
   witness_text(muderator, M('indefinite', muderator) .. ' stares off into space, deep in thought.  A cat walks by.  The same cat?')
end

add_functions{
   ['container thing'] = function(thing) return thing.container end,
   ['place-text container'] = function(container)
      local title = M('name', container)
      local hr = string.rep('-', #title)
      local detail = M('detail', container)
      local contents = container.contents
      local content_list = ''
      if #contents then
         content_list = "\nYou see here: " .. M('indefinite', contents[1])
         for i=2,#contents do
            content_list = content_list .. ', ' .. M('indefinite', contents[i])
         end
      end
      return title .. "\n" .. hr .. "\n" .. detail .. content_list
   end,
   ['put-in thing container'] = move_content,
   ['player look'] = function(player)
      local container = M('container', player)
      if not container then
         player_text(player, 'You don\'t appear to be anywhere. You feel uneasy as you consider this.')
      else
         player_text(player, M('place-text', container))
      end
      return true
   end,
   ['subject-bind-search rename-to'] = 'global',
   ['object-bind-search rename-to'] = 'none',
   ['subject-bind-limit rename-to'] = 'single',
   ['muderator rename-to thing string-type'] = function(muderator, thing, name)
      player_text(muderator, 'You decide that \'' .. name.string .. '\' is a more fitting name for that.  The universe agrees.')
      witness_change(muderator)
      thing.name = name.string
   end,
   ['subject-bind-search describe-as'] = 'global',
   ['object-bind-search describe-as'] = 'none',
   ['subject-bind-limit describe-as'] = 'single',
   ['muderator describe-as thing string-type'] = function(muderator, thing, desc)
      player_text(muderator, 'You think that would be a more fitting description.  The universe agrees.')
      witness_change(muderator)
      thing.long_desc = desc.string
   end,
   ['subject-bind-search whisk-to'] = 'global',
   ['object-bind-search whisk-to'] = 'global',
   ['muderator whisk-to player container'] = function(muderator, player, container)
      local m_name = M('indefinite', muderator)
      local p_name = M('indefinite', player)
      if muderator == player then
         player_text(player, 'You concentrate on a far off place. Suddenly you are whisked through time and space.')
         witness_text(player, p_name .. ' stares off into space, lost in thought. He disappears with a loud *POP*!')
      else
         player_text(player, m_name .. ' suddenly whisks you away! Space and time tears and flows around you.')
         witness_text(player, m_name .. ' suddenly whisks ' .. p_name .. ' away!')
      end
      do_to('put-in', player, container)
      player_text(player, 'You feel a bone-shaking jolt accompanied by a tremendous *POP*, and you realize you\'re somewhere else.')
      witness_text(player, 'You hear a loud *POP* as ' .. p_name .. ' suddenly appears.')
      F{player, 'look'}(player)
      return true
   end,
             }

local void = get_thing('void') or add_room('void', 'The Void', 'A formless, black emptiness.')
force_do('whisk God to the Void')

-- Creating things
-- <Adding carryables> ~ "item" --> put in the list below!
add_atoms{create='verb', item='thing', [{'rock', 'coin', 'key'}] = 'item'}
add_functions{
   ['subject-bind-search create'] = 'none',
   ['muderator create thing'] = function(muderator, thing_group)
      local types = thing_group.adjectives
      table.insert(types, thing_group.noun)
      local thing = get_thing(create_thing(thing_group.noun, {types=types, name=thing_group.noun}))
      local container = M('container', player)
      do_to('put-in', thing, container)
      player_text(muderator, 'You will ' .. M('indefinite', thing) .. ' into being.')
      witness_text(muderator, M('indefinite', muderator) .. ' concentrates for a moment. Before your very eyes, ' .. M('indefinite', thing) .. ' appears!')
   end,
-- Creating Items
-- *****************************
	['muderator create item'] = function(muderator, i)
		DEBUG('Create_Item called...')
		--local item = add_item()
		local types = i.adjectives
		table.insert(types, i.noun)
		local item_thing = get_thing(create_thing(i.noun, {types=types,name=i.noun}))
		-- <Item_Thing ~ nil> DEBUG
		-- DEBUG('ITEM-THING --> <' .. item_thing.name .. '>')
		-- ------------------------
		local container = M('container', muderator)
      		do_to('put-in', item_thing, container)
      		player_text(muderator, 'You will ' .. M('indefinite', item_thing.name) .. ' into being.')
      		witness_text(muderator, M('indefinite', muderator) .. ' makes a(n) ' .. M('indefinite', item_thing.name) .. ' appears!')
   	end,
-- *****************************
             }
-- Creating rooms
add_functions{
   ['muderator create room'] = function(muderator, room_group)
      local room = add_room()
      player_text(muderator, 'You will room into being. You decide to call it \'' .. room.id .. '\'.')
      witness_text(muderator, M('indefinite', muderator) .. ' stares off into space for a moment. The world feels bigger, somehow.')
      return true
   end,
             }


-- Doorways to elsewhere
add_atoms{door='portal', portal='thing', go='verb', to='preposition'}

add_functions{
   ['exit portal'] = function(portal) return portal.exit or void end,
   ['name portal'] = function(portal) return 'glowing portal' end,
   ['subject-bind-limit go'] = 'single',
   ['player go portal'] = function(player, portal)
      player_text(player, 'You walk through ' .. M('definite', portal) .. '.')
      local p_name = M('indefinite', player)
      witness_text(player, p_name .. ' walks through ' .. M('indefinite', portal) .. '.')
      do_to('put-in', player, get_thing(M('exit', portal)))
      witness_text(player, p_name .. ' enters through ' .. M('indefinite', portal) .. '.')
      F{player, 'look'}(player)
      return true
   end,
   ['subject-bind-search create-to'] = 'none',
   ['object-bind-search create-to'] = 'global',
   ['object-bind-limit create-to'] = 'single',
   ['muderator create-to portal room'] = function(muderator, portal_phrase, room)
      printTable(room, DEBUG)
      local id = create_thing(portal_phrase.noun, {types={portal_phrase.noun}, exit=room.id})
      local portal = get_thing(id)
      do_to('put-in', portal, M('container', muderator))
      local portal_text = capitalize(M('indefinite', portal))
      player_text(muderator, 'You concentrate on connecting to another place. ' .. portal_text .. ' appears before you! You decide to call it \'' .. id .. '\'.')
      witness_text(muderator, M('indefinite', muderator) .. ' stares into space with a piercing gaze.  ' .. portal_text .. ' appears before them!')
      return true
   end
             }
-- Directional Portals
-- ***************************************************************************
add_atoms { [{'north', 'east', 'south', 'west'}]="portal" }
add_functions
{	
	-- <NOT TESTED>!!!
	['name north'] = function(north) return 'Path to the North'	end,
	['muderator create-to north room'] = function(muderator, port, room)
	  local id=create_thing(port.noun, {types={port.noun}, exit=room.id})
      	  local portal = get_thing(id)
	  portal.long_desc = 'North'
	  portal.name = 'North'
      	  do_to('put-in', portal, M('container', muderator))
      	  local portal_text = capitalize(M('indefinite', portal))
	  player_text(muderator, 'You concentrate on connecting to another place. ' .. portal_text .. ' appears before you! You decide to call it \'' .. portal.name .. '\'.')
      	  witness_text(muderator, M('indefinite', muderator) .. ' stares north into space with a piercing gaze.  ' .. portal_text .. ' appears before them!')
	end,


	['player go north'] = function(player, portal)
	  player_text(player, 'You travel north...')
	  witness_text(player, M('indefinite', player) .. ' travels north.')
	  do_to('put-in', player, get_thing(M('exit', portal)))
	end,
	['player go east'] = function(player, portal)
	  player_text(player, 'You travel east...')
	  witness_text(player, M('indefinite', player) .. ' travels east.')
	  do_to('put-in', player, get_thing(M('exit', portal)))
	end,
	['player go south'] = function(player, portal)
	  player_text(player, 'You travel south...')
	  witness_text(player, M('indefinite', player) .. ' travels south.')
	  do_to('put-in', player, get_thing(M('exit', portal)))
	end,
	['player go west'] = function(player, portal)
	  player_text(player, 'You travel west...')
	  witness_text(player, M('indefinite', player) .. ' travels west.')
	  do_to('put-in', player, get_thing(M('exit', portal)))
	end
}			 
-- ****************************************************************************
-- Cliff!
add_atoms{cliff="portal"}
add_functions{
   ['name cliff'] = function(cliff) return 'steep cliff' end,
   ['player go cliff'] = function(player, portal)
      player_text(player, 'You get a running start and leap off ' .. M('definite', portal) .. "!\nYou tumble down to the bottom!")
      local p_name = M('indefinite', player)
      witness_text(player, p_name .. ' takes a running leap off ' .. M('indefinite', portal) .. '!')
      do_to('put-in', player, get_thing(M('exit', portal)))
      witness_text(player, p_name .. ' comes tumbling down ' .. M('indefinite', portal) .. '!  They land hard, and after a moment, stand and dust themself off,')
      F{player, 'look'}(player)
      return true
   end
             }
-- Inventory?
-- ****************************************************************************
add_atoms{[{'inventory', 'get', 'drop'}]='verb', item='noun'}
add_functions
{
	['player inventory'] = function(player)
		open_inventory(player.name)
	end,
	--['subject-bind-limit get'] = 'single',
	--['object-bind-limit get'] = 'single',
	['subject-bind-limit get'] = 'any',
	['player get item'] = function(player, item)
		-- <DEBUG>
		player_text(player, 'IN GET ITEM')
		-- Remove item from original container
		remove_content(item)
		add_to_inventory(player.name, item)
	end,
	['subject-bind-search drop'] = 'inventory',
	['player drop item'] = function(player, item)
		-- Remove item from inventory
		DEBUG('Dropped Item? <' .. item.name .. '>')
		player_text(player, '<DEBUG>: Dropping <' .. item.name .. '>')
		--DEBUG('Dropped Item\'s Container <' .. M('container', item) .. '>')
		remove_content(item)
		drop_from_inventory(player.name, item)
	end
}
-- ****************************************************************************
-- Talking and other pleasantries
add_atoms{[{'say', 'dance', 'apologize', 'bark', 'bmoc', 'combhair', 'slap', 'flex', 'nod', 'relax', 'bow', 'cheer', 'grin', 'chuckle'}]='verb', to='preposition'}

add_functions
{
   ['subject-bind-search emote'] = 'none',
   ['player emote string-type'] = function(player, msg)
      local text = M('indefinite', player)
      if msg.string:sub(1,1) ~= "'" then
         text = text .. ' '
      end
      text = text .. msg.string
      player_text(player, text)
      witness_text(player, text)
   end,
   ['subject-bind-search say'] = 'none',
   ['player say string-type'] = function(player, msg)
      player_text(player, 'You say "' .. msg.string .. '"')
      witness_text(player, M('indefinite', player) .. ' says "' .. msg.string .. '"')
   end,
   ['subject-bind-search say-to'] = 'none',
   ['player say-to string-type thing'] = function(player, msg, thing)
      player_text(player, 'You say "' .. msg.string .. '" to ' .. M('definite',	thing) .. '.')
      witness_text(player, M('indefinite', player) .. ' says "' .. msg.string .. '" to ' .. M('indefinite', thing) .. '.')
      end,
      ['player dance'] = function(player)
        player_text(player, 'You burst into dance.')
        witness_text(player, M('indefinite', player)..' bursts into dance.')
      	end,
      ['player dance player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' dances with ' .. M('indefinite', p2) .. ' wildly.')
	player_text(p1, 'You dance wildly with ' .. M('indefinite', p2) .. '.')
	end,
      ['player relax'] = function(player)
        witness_text(player, M('indefinite', player)..' sits down, lounging with complete abandon.');
	player_text(player, 'You sit down and lounge with complete abandon.');
      	end,
      ['player bmoc'] = function(player)
        witness_text(player, M('indefinite', player)..' is the Big Man On Campus!');
	player_text(player, 'You\'re the Big Man On Campus!');
      	end,
      ['player combhair'] = function(player)
        witness_text(player, M('indefinite', player)..' combs his/her own hair.');
	player_text(player, 'You comb your own hair.');
      	end,
      ['player combhair player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' combs ' .. 
			 M('indefinite', p2)..'\'s hair.');
	player_text(p1, 'You comb ' .. M('indefinite', p2) .. '\'s hair.');
      	end,
      ['player flex'] = function(player)
        witness_text(player, M('indefinite', player)..' flexes his muscles. So strong!');
	player_text(player, 'You flex your muscles. So strong!');
      	end,
      ['player nod'] = function(p)
        witness_text(p, M('indefinite', p) ..' nods.');
	player_text(p, 'You nod.');
      	end,
      ['player nod player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p2) .. ' nods at you.');
	player_text(p1, 'You nod at ' .. M('indefinite', p2) .. '.');
      	end,
      ['player bark'] = function(p)
        witness_text(p, M('indefinite', p) .. ' barks. Woof woof!');
	player_text(p, 'You bark. Woof woof!');
	add_atoms { bark = 'verb' };
      	end,
      ['player bark player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' barks at ' .. 
			 M('indefinite', p2) .. '. Woof woof!');
	player_text(p1, 'You bark at ' .. M('indefinite', p2) .. '. Woof woof!');
      	end,
      ['player bow'] = function(p)
        witness_text(p, M('indefinite', p) .. ' bows with great honor.');
	player_text(p, 'You bow with great honor.');
	add_atoms { bow = 'verb' };
      	end,
      ['player bow player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' bows with great honor to ' 
			 .. M('indefininte', p2) .. '.');
	player_text(p1, 'You bow to ' .. M('indefinite', p2) .. '.');
      	end,
      ['player apologize'] = function(p)
        witness_text(p, M('indefinite', p) ..' apologizes for being born.'		);
	player_text(p, 'You apologize for being born.');
      	end,
      ['player apologize player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' apologies to ' .. 
			 M('indefinite', p2) .. '. Sorry, bro!');
	player_text(p1, 'You apologize to ' .. M('indefinite', p2) ..'.');
      	end,
      ['player cheer'] = function(p)
        witness_text(p, M('indefinite', p) .. ' cheers - Hurrah!');
	player_text(p, 'You cheer. Hurrah!');
      	end,
      ['player cheer player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' cheers at you. Wooo!');
	player_text(p1, 'You cheer at ' .. M('indefinite', p2) .. '. Wooo!');
      	end,
      ['player grin'] = function(p)
        witness_text(p, M('indefinite', p) .. ' grins to himself.');
	player_text(p, 'You grin to yourself. Tee hee...');
      	end,
      ['player grin player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' grins at you. He knows...');
	player_text(p1, 'You grin at ' .. M('indefinite', p2) .. '. You know...');
      	end,
      ['player chuckle'] = function(p)
        witness_text(p, 'Chuckles good-naturedly.');
	player_text(p, 'You chuckle good-naturedly.');
      	end,
      ['player chuckle player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' chuckles at you, full of mirth!');
	player_text(p1, 'You chuckle at ' .. M('indefinite', p2) .. ', full of mirth!');
      	end,
      ['player slap'] = function(player)
        witness_text(player, M('indefinite', player)..' slaps himself with a trout. Ouch!');
	player_text(player, 'You slap yourself with a trout. Ouch!');
      end,
      ['player slap player'] = function(p1, p2)
	witness_text(p1, M('indefinite', p1) .. ' slaps ' .. M('indefinite', p2) .. ' with a trout. Ouch!')
	player_text(p1, 'You slap ' .. M('indefinite', p2) .. ' with a trout. Ouch!')
      end
}
