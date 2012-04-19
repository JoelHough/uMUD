add_atoms{muderator='player'}

add_player('God', {types={'muderator'}, name='God'})
add_player('MysteriousForce', {types={'muderator'}, name='a mysterious force'})

F'put-in muderator room'(get_thing('God'), get_room('void'))

add_functions{
   ['muderator create thing'] = function (player, verb, thing_group)
      local types = thing_group.adjectives
      table.insert(types, thing_group.noun)
      local thing = get_thing(create(thing_group.noun, {types=types, name=thing_group.noun}))
      F{'put-in', thing, player.container}(thing, player.container)
      player_text(player, 'You create a ' .. thing_group.noun)
      witness_text(player, player.name .. ' creates a ' .. thing_group.noun)
   end,
   ['muderator create-in thing container'] = function (player, verb, thing_group, container_thing) print(player.name .. ' creates a ' .. thing_group.noun .. ' in the ' .. container.name) end
             }