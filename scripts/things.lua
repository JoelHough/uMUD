-- Things.lua -- 
--[[
   Logical progression for creation: Command is typed in, parser does its thing, then it calls 
   there_is_a(thing) and is_a_kind_of(parent, thing). From there, it's time to create the <thing>.
   Upon creation, it needs a place in things {} and it needs a unique ID, and a container it's housed in.

   ]]--

local things = { }

function get_thing(id)
   return things[id:lower()]
end

function add_thing(name, data)
   local id = name:lower()
   if things[id] then
      ERROR('Tried adding thing \'' .. id .. '\' that already exists!')
      return nil
   end
   things[id] = data
   return id
end

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

add_atoms{[{'create', 'destroy', 'say', 'description'}]='verb', thing='noun', [{'in', 'to'}]='preposition', 'say-to'}
add_functions{
   ['bind-modes create'] = {subject='none', object='none'},
   ['bind-modes create-in'] = {subject='none', object='standard'},
   ['describe thing'] = function(thing) return 'It looks like an ordinary ' .. thing.name end, -- TODO: What to do about second vs. third person descriptions?
   ['create-in thing container'] = function (thing_group) print('Creating a ' .. thing_group.noun) end,
   ['bind-modes say-to'] = {subject='none', object='standard'},
   ['thing say-to string-type thing'] = function (speaker, verb, msg, target) print(speaker.name .. ' says "' .. msg .. '" to ' .. target.name .. '.') end
             }
