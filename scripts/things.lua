-- Things.lua -- 
--[[
   Logical progression for creation: Command is typed in, parser does its thing, then it calls 
   there_is_a(thing) and is_a_kind_of(parent, thing). From there, it's time to create the <thing>.
   Upon creation, it needs a place in things {} and it needs a unique ID, and a container it's housed in.

   ]]--

things = { }
thing_counters = {}

function get_thing(id)
   return things[id:lower()]
end

function add_thing(name, data)
   local id = name:lower()
   if things[id] then
      ERROR('Tried adding thing \'' .. id .. '\' that already exists!')
      return nil
   end
   data.id = id
   things[id] = data
   add_atoms{[id]='pronoun'}

   DEBUG('get_thing --> <' .. id .. '>')

   return id
end



--New n' improved function takes the function's type (synonymous with name at this juncture), and a table of values.
-- The Idea is to return a unique Item ID (String#).
function create_thing(type, t_entries)

   --If this type of 'thing' hasn't been created yet, create the first one.
   --This also instantiates the 'root' thing, an un numbered representation of the entire category of this particular thing. 
   if not thing_counters[type] then
      DEBUG("Type is" .. type)
      thing_counters[type] = { name = type, count = 0, open_ids = { } }
      DEBUG('Created counter for ' .. type)
   end
   local count = thing_counters[type].count + 1
   local id = type .. count
   add_thing(id, t_entries)
   DEBUG (type .. " created, ID is " .. id)
   thing_counters[type].count = count --Update the quantity of things[type]
   return id
end




 

function destroy(thing, ...)
   
   if not things[thing] then
      return nothing
      
   else
      --things[thing]
   end
end

-- add_atoms{[{'say', 'description'}]='verb', thing='noun', [{'to'}]='preposition', 'say-to'}
-- add_functions{
--    ['describe thing'] = function(thing) return 'It looks like an ordinary ' .. thing.name end, -- TODO: What to do about second vs. third person descriptions?
--    ['create-in thing container'] = function (thing_group) print('Creating a ' .. thing_group.noun) end,
--    ['bind-modes say-to'] = {subject='none', object='standard'},
--    ['thing say-to string-type thing'] = function (speaker, verb, msg, target) witness_text(speaker, speaker.name .. ' says "' .. msg .. '" to ' .. target.name .. '.') end
--              }
