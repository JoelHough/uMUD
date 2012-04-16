require'types'
require'things'
-- Portals lead to containers.
-- They are one way only!  If you want a door into a house, you must also add a
-- door that leads out!
-- Portals are not themselves things, but in-game portals should be.  The 'go'
-- function uses standard bind-mode, so most of the time local things will be
-- searched when looking for a portal.

local function thing_go_portal(thing, verb, portal)
   F{'put-in', thing.type, portal.type}(thing, portal.exit)
   F{thing.type, 'look', thing.container.type}(thing, 'look', thing.container)
end

add_atoms{'portal', go='verb'}
add_functions{
   ['thing go portal'] = thing_go_portal
             }