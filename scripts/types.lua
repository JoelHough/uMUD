-- uMUD Object Heirarchy
require'utils'
require'log'

collider = { }

function get(atom_name)
   return collider[atom_name]
end

---------------------------------------------------------------------------------------
function is_a_kind_of(child, parent)


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


function there_is_a(child)

   if not collider[child] then
      collider[child] = { name = child, anc = { } , desc = { } }
   else
      WARNING(child .. " already exists")
   end
end

---------------------------------------------------------------------------------------

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
   there_is_a("one")
   there_is_a("two")
   there_is_a("three")
   there_is_a("four")
   
   is_a_kind_of("two","one")
   is_a_kind_of("three","one")
   is_a_kind_of("four","two")
   is_a_kind_of("four","three")


   results =  get_all_children("one")
   INFO("Children of one \t", unpack(results) )
   results = get_all_parents("four")
   INFO("Parents of four \t", unpack(results) )

   --test is_a_kind_of
   --test there_is_a


   TEST'End of type system test'
end

--Run test--
test()