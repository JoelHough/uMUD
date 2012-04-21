require'base'

-- Protip:  If you are accessing a field on a thing, you are probably doing it wrong.
--  Use the function hierarchy. F{}()

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
local god = add_player('God', {types={'muderator'}})
local force = add_player('A mysterious force', {types={'muderator'}})
local function force_do(command)
   local ast, msg = parse_command(command)
   printTable(ast, DEBUG)
   return bind_and_execute(force, ast)
end

require'things'
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
      things[player.id] = nil
      server_disconnect_player(player.id)
   end
             }

-- Being in things, including rooms
require'containers'
require'rooms'
add_atoms{room={'container', 'thing'}, [{'look', 'whisk', 'name'}]='verb', [{'to', 'as'}]='preposition'}

add_functions{
   ['container thing'] = function(thing) return thing.container end,
   ['place-text thing'] = function(thing)
      local title = M('name', thing)
      local hr = string.rep('-', #title)
      local detail = M('detail', thing)
      return title .. "\n" .. hr .. "\n" .. detail
   end,
   ['put-in thing container'] = move_content,
   ['player look'] = function(player) 
      local container = M('container', player)
      if not container then 
         player_text(player, 'You don\'t appear to be anywhere.  You feel uneasy as you consider this.')
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
         player_text(player, 'You concentrate on a far off place.  Suddenly you are whisked through time and space.')
         witness_text(player, p_name .. ' stares off into space, lost in thought.  He disappears with a loud *POP*!')
      else
         player_text(player, m_name .. ' suddenly whisks you away!  Space and time tears and flows around you.')
         witness_text(player, m_name .. ' suddenly whisks ' .. p_name .. ' away!')
      end
      do_to('put-in', player, container)
      player_text(player, 'You feel a bone-shaking jolt accompanied by a tremendous *POP*, and you realize you\'re somewhere else.')
      witness_text(player, 'You hear a loud *POP* as ' .. p_name .. ' suddenly appears.')
      F{player, 'look'}(player)
      return true
   end,
             }

local void = add_room('void', 'The Void', 'A formless, black emptiness.')
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
      witness_text(muderator, M('indefinite', muderator) .. ' concentrates for a moment.  Before your very eyes, ' .. M('indefinite', thing) .. ' appears!')
   end,
             }
-- Creating rooms
add_functions{
   ['muderator create room'] = function(muderator, room_group)
      local room = add_room()
      player_text(muderator, 'You will room into being.  You decide to call it \'' .. room.id .. '\'.')
      witness_text(muderator, M('indefinite', muderator) .. ' stares off into space for a moment.  The world feels bigger, somehow.')
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
      player_text(muderator, 'You concentrate on punching a hole to another place.  A portal opens before you!  You decide to call it \'' .. id .. '\'.')
      witness_text(muderator, M('indefinite', muderator) .. ' stares into space with a piercing gaze.  A portal opens before him!')
      return true
   end
             }

-- Talking and other pleasantries
add_atoms{say='verb', to='preposition'}

add_functions{
   ['player say-to string-type thing'] = function(player, string, thing)
      player_text(player, 'You say "' .. msg.string .. '" to ' .. M('definite', thing) .. '.')
      witness_text(player, M('indefinite', player) .. ' says "' .. msg.string .. '" to ' .. M('indefinite', thing) .. '.')
   end
             }