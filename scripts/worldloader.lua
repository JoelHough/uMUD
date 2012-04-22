--[[ World loader -- Hard coded functions suitable for world creation.
   
   The basic idea is this: A muderator (At this juncture, one with Lua experience) creates a simple
   file in the form of a table. This table contains all entries that are part of the most basic implementation
   of a game world. The buildWorld function takes in the filename that the table is stored in, and reads through it.

   It's important to note that at this time, the function expects two tables (Things, and Containers).
   Future revisions will remove this restriction and allow for the creation of anything.

   The reason for two tables falls into this line of thought;
   There are two major types in the world. Things, and Containers. Stuff, and places to put stuff.
   In future revisions, I envision the need for verbs, actions, emotes, and other parts of the game. 


   The functionality of this table is as follows:
   1- A file is read in
   2- That file's table entires are iterated through.
   3- Using add_atoms, the nested tables are added into the heirarchy.
   4- At the bottom of each nesting, there are base things/containers with flavor text descriptions. These are then created and placed into the game.

   Joel's comments:

   I think, for the world builder, it would be easier if you split type making and instance making into two parts. 
   It seems like it will be difficult later to set up room layout and put things in them with this setup.  
   Also, the atoms are getting added but the relationships are not.  
   The function layout and thought process look fine, though.


   I WISH I COULD DO:
   Any amount of table entries, from things to character classes to emotes.
   Plain english (Bartle-ized) world building. Example: There is a dirk that is a type of sword
   Creating links between rooms (using portals)
   Creating AI

   --]]


function buildWorld(file)
   dofile(file)
   local types = { Things, Containers }  -- CURRENT EXPECTED FORMAT FOR INPUT FILE
   local instances = { } -- Table housing the actual instances of the things created. 

   for k,v in pairs(types) do
      worldHelper(v);
   end
   instanceBuilder(instances)
end

function typeBuilder(t, parent)
   for k,v in pairs(t) do
      if (type(v) == "table") then
	 DEBUG("Adding: " .. tostring(k).lower(k))
	 add_atom(tostring(k).lower(k))
	 if parent then
	    add_parent(tostring(k).lower(k), parent)
	    worldHelper(v, tostring(k).lower(k))
	 else
	    worldHelper(v, k)
	 end
	 
      else
	 DEBUG(tostring(k).lower(k) .. ' description '  .. '=' .. v)

	 -- Instance Handling:
	 table.insert(instances, k)
      end
   end
end


-- Uses add_thing to create instances of stuff in the game. Doesn't really do anything else. At this point, the muderator needs to make stuff 
function instanceBuilder(instances)
   for k,v in pairs(instances) do
      if add_thing(k, v) then
	 DEBUG("Successfully added " .. k .. " into the game.")
      end
   end   
end