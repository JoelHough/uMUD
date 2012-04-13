-- Things.lua -- 
--[[
   Logical progression for creation: Command is typed in, parser does its thing, then it calls 
   there_is_a(thing) and is_a_kind_of(parent, thing). From there, it's time to create the <thing>.
   Upon creation, it needs a place in things {} and it needs a unique ID, and a container it's housed in.

   ]]--
require('types')

things = { }


--Function for creation. Places the supplied 'thing' into the list of things. Also keeps a count of how many of
--That particular thing exist at present.
function create(thing, ...)

   --If this type of 'thing' hasn't been created yet, create the first one.
   --This also instantiates the 'root' thing, an un numbered representation of the entire category of this particular thing. 
   if not things[thing] then
      things[thing] = { count = 1, open_ids = { } }
      things[thing .. 1] = { name='TODO: Description', type = thing, container='TODO: Originating container' }
   else
      local count = things[thing].count + 1
      things[thing .. count] = { name = 'TODO: Description', type = thing, container = 'TODO: Originating container' }
      things[thing].count = count --Update the quantity of things['thing']
   end


end



function destroy(thing, ...)
   
   if not things[thing] then
      return nothing
      
   else
      --things[thing]
   end
end