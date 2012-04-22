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
add_atoms{eval='verb'}
add_functions{
   ['connect player'] = function(player)
      force_do('whisk ' .. player.id .. ' to the Void')
   end,
   ['everything'] = things,
   ['detail thing'] = function(thing) return thing.long_desc or 'It is very non-descript.' end,
   ['name thing'] = function(thing) return thing.name or 'nameless thing' end,
   ['definite thing'] = function(thing) return 'the ' .. M('name', thing) end,
   ['indefinite thing'] = function(thing) return 'a ' .. M('name', thing) end, -- TODO 'an'
   ['definite player'] = function(player) return M('name', player) end,
   ['indefinite player'] = function(player) return M('name', player) end,
   ['player disconnect'] = function(player)
      witness_text(player, M('indefinite', player) .. ' vanishes!')
      remove_content(player)
      things[player.id] = nil
      server_disconnect_player(player.id)
   end,
   ['subject-bind-search eval'] = 'none',
   ['muderator eval string-type'] = function(muderator, cmd)
      player_text(muderator, "Your words run deep.")
      loadstring(cmd.string)()
   end
             }

-- Being in things, including rooms
require'containers'
require'rooms'
add_atoms{room={'container', 'thing'}, [{'look', 'whisk', 'name'}]='verb', [{'to', 'as'}]='preposition'}

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
add_atoms{create='verb'}
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
      local id = create_thing('portal', {types={'portal'}, exit=room.id})
      do_to('put-in', get_thing(id), M('container', muderator))
      player_text(muderator, 'You concentrate on punching a hole to another place. A portal opens before you! You decide to call it \'' .. id .. '\'.')
      witness_text(muderator, M('indefinite', muderator) .. ' stares into space with a piercing gaze. A portal opens before him!')
      return true
   end
             }

-- Talking and other pleasantries
add_atoms{say='verb', to='preposition'}

add_functions
{
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
      ['subject-bind-search dance'] = 'none',
      ['player dance'] = function(player)
        player_text(player, 'You burst into dance.')
        witness_text(player, M('indefinite', player)..' bursts into dance.')
        add_atoms{dance='verb'}
      	end,
      ['player relax'] = function(player)
        witness_text(player, M('indefinite', player)..' sits down, loungin		g with complete abandon.');
	player_text(player, 'You sit down and lounge with complete abandon.');
	add_atoms{ relax = 'verb' };
      	end,
      ['player bmoc'] = function(player)
        witness_text(player, M('indefinite', player)..' is the Big Man On Campus!');
	player_text(player, 'You\'re the Big Man On Campus!');
	add_atoms{ bmoc = 'verb' };
      	end,
      ['player combhair'] = function(player)
        witness_text(player, M('indefinite', player)..' combs his/her own		hair.'		);
	player_text(player, 'You comb your own hair.');
	add_atoms{ combhair = 'verb' };
      end,
      ['player combhair player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' combs ' .. 
			 M('indefinite', p2)..'\'s hair.');
	player_text(p1, 'You comb ' .. M('indefinite', p2) .. '\'s hair.');
      end,
      ['player flex'] = function(player)
        witness_text(player, M('indefinite', player)..' flexes his muscles		. So strong!');
	player_text(player, 'You flex your muscles. So strong!');
	add_atoms{ flex = 'verb' };
      end,
      ['player nod'] = function(p)
        witness_text(p, M('indefinite', p) ..' nods.');
	player_text(p, 'You nod.');
	add_atoms { nod = 'verb' };
      end,
      ['player nod player'] = function(p1, p2)
        witness_text(p1, M('indefinite', player) .. ' nods at you.');
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
	add_atoms { apologize = 'verb' };
      end,
      ['player apologize player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' apologies to ' .. 
			 M('indefinite', p2) .. '. Sorry, bro!');
	player_text(p1, 'You apologize to ' .. M('indefinite', p2) ..
			'.');
      end,
      ['player cheer'] = function(p)
        witness_text(p, M('indefinite', p) .. ' cheers - Hurrah!');
	player_text(p, 'You cheer. Hurrah!');
	add_atoms { cheer = 'verb' };
      end,
      ['player cheer player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' cheers at you. Wooo!');
	player_text(p1, 'You cheer at ' .. M('indefinite', p2) .. 
			'. Wooo!');
      end,
      ['player grin'] = function(p)
        witness_text(p, M('indefinite', p) .. ' grins to himself.');
	player_text(p, 'You grin to yourself. Tee hee...');
	add_atoms { grin = 'verb' };
      end,
      ['player grin player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' grins at you. He knows...');
	player_text(p1, 'You grin at ' .. M('indefinite', p2) .. '. You know...');
      end,
      ['player chuckle'] = function(p)
        witness_text(p, 'Chuckles good-naturedly.');
	player_text(p, 'You chuckle good-naturedly.');
	add_atoms { chuckle = 'verb' };
      end,
      ['player chuckle player'] = function(p1, p2)
        witness_text(p1, M('indefinite', p1) .. ' chuckles at you, full of mirth!');
	player_text(p1, 'You chuckle at ' .. M('indefinite', p2) .. ', full of mirth!');
      end,
      ['player slap'] = function(player)
        witness_text(player, M('indefinite', player)..' slaps himself with a trout. Ouch!');
	player_text(player, 'You slap yourself with a trout. Ouch!');
	add_atoms{ slap = 'verb' };
      end
<<<<<<< HEAD
=======
// end -B
>>>>>>> f422ca48f65d0d5c921a8bca358ffb3f78a82baa
}
