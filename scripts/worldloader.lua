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
   --]]


function buildWorld(file)
   dofile(file)
   local types = { Things, Containers }  -- CURRENT EXPECTED FORMAT FOR INPUT FILE
   function worldHelper(t)
      for k,v in pairs(t) do
         if (type(v) == "table") then
            DEBUG("Adding: " .. tostring(k).lower(k))
	    add_atoms(k)
            table.insert(printed, v)
            worldHelper(v)
	 else
	    DEBUG(tostring(k).lower(k) .. ' description '  .. '=' .. v)
	    create_thing(tostring(k).lower(k), { description = v } ) --Create the first instance of the thing. 
	 end
      end
   end
   for k,v in pairs(types) do
      worldHelper(v);
   end
end
 