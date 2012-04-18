require'players'
require'containers'
require'rooms'

add_atoms{muderator='player'}

add_player('God', {type='muderator', name='God'})
add_player('MysteriousForce', {type='muderator', name='a mysterious force'})

F'put-in muderator room'(get_thing('God'), get_room('void'))

add_functions{
   ['muderator create thing'] = function (player, verb, thing_group) print(player.name .. ' creates a ' .. thing_group.noun) end,
   ['muderator create-in thing container'] = function (player, verb, thing_group, container_thing) print(player.name .. ' creates a ' .. thing_group.noun .. ' in the ' .. container.name) end
             }