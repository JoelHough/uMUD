-- uMUD Object Heirarchy
require'functional'
require'utils'
require'log'

collider = { }

function get(atom_name)
   return collider[atom_name]
end

---------------------------------------------------------------------------------------
function add_parent(child, parent)

   if collider[child] then
      if collider[parent] then
         if table.find(get_all_parents(child), parent) then
            -- Already inherits
            WARNING(child .. ' already inherits from ' .. parent)
            return nil
         end
         if table.find(get_all_children(child), parent) then
            -- Cycle==Bad
            WARNING(parent .. ' inherits from ' .. child .. '.  Not linking to avoid cycles.')
            return nil
         end
         table.insert(collider[child].anc, collider[parent])
         table.insert(collider[parent].desc, collider[child])
      else
	 print(parent .. " doesn't exist!")
      end
   else
      print(child .." doesn't exist!")
   end

end


function add_atom(child)

   if not collider[child] then
      collider[child] = { name = child, anc = { } , desc = { } }
   else
      WARNING(child .. " already exists")
   end
end

---------------------------------------------------------------------------------------
local function is_child_of_(child_atom, parent_atom)
   if child_atom == parent_atom then return true end
   return any(child_atom.anc, bind2(is_child_of_, parent_atom))
end

function is_child_of(child, parent)
   local child_atom = get(child)
   if not child_atom then
      ERROR(child .. ' does not exist!')
      return false
   end
   local parent_atom = get(parent)
   if not parent_atom then
      ERROR(parent .. ' does not exist!')
      return false
   end
   return is_child_of_(child_atom, parent_atom)
end

function get_all_children(parent)
   return get_all(parent, "desc")
end


function get_all_parents(children)
   return get_all(children, "anc")
end


function get_all(root, rel)

   local to_visit = { collider[root] }
   local visited = { }

   while next(to_visit) do

      local node = table.remove(to_visit, 1)

      --Check to see if node is in visited.
      -- if it is, continue
      if not contains(visited, node) then
	 table.insert(visited,node)
	 for i,v in ipairs(node[rel]) do
	    table.insert(to_visit, v )
	 end
      end
   end

   
   results = { }
   for i = 1,#visited do
      table.insert(results,visited[i].name)
   end
   
   return results
end

-----------------------------------------------------------------------------------

--Check for table membership
function contains(t, e)

   for i = 1, #t do
      if t[i] == e then return true end
   end
   return false
end


function test()
   TEST'Beginning type system test'
   add_atom("one")
   add_atom("two")
   add_atom("three")
   add_atom("four")
   
   add_parent("two","one")
   add_parent("three","one")
   add_parent("four","two")
   add_parent("four","three")


   results =  get_all_children("one")
   INFO("Children of one \t", unpack(results) )
   results = get_all_parents("four")
   INFO("Parents of four \t", unpack(results) )

   --test add_parent
   --test add_atom


   TEST'End of type system test'
end

--Run test--
test()