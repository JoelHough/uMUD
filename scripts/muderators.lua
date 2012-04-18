add_atoms{muderator='player'}

add_player('God', {types={'muderator'}, name='God'})
add_player('MysteriousForce', {types={'muderator'}, name='a mysterious force'})

F'put-in muderator room'(get_thing('God'), get_room('void'))

add_functions{
   ['muderator create thing'] = function (player, verb, thing_group) create(thing_group.noun, { container = player.container, description = "A run of the mill Thing" } ) print(player.name .. ' creates a ' .. thing_group.noun) end,
   ['muderator create-in thing container'] = function (player, verb, thing_group, container_thing) print(player.name .. ' creates a ' .. thing_group.noun .. ' in the ' .. container.name) end
             }