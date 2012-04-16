require'types'
require'functions'

local function move_thing(thing, new_container)
   if thing.container then
      local from = thing.container.contents
      for i, v in ipairs(from) do
         if v == thing then
            table.remove(from, i)
            break
         end
      end
   end
   thing.container = new_container
   table.insert(new_container.contents, thing)
end

add_atoms{[{'container', 'contents'}]='noun', put='preposition', 'put-in'}

add_functions{
   ['put-in thing container'] = insert_thing,
             }