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


--Main function. Does all of the heavy lifting.
function buildWorld(file)
   dofile(file)
   gameData = { } -- Table containing ID's of all the stuff created in this new 'game'
   local types = { Things, Containers }  -- CURRENT EXPECTED FORMAT FOR INPUT FILE
   local instances = { } -- Table housing the actual instances of the things created. 

   for k,v in pairs(types) do
      typeBuilder(v);
   end

   --TODO: Rooms, Portals, Functions, Things.
end

-- Atom building from everything in supplied .lua file.
function typeBuilder(t, parent)
   for k,v in pairs(t) do
     local name = tostring(k).lower(k)
      if (type(v) == "table") then

	 DEBUG("Adding: " .. name)
	 table.insert(instances, name) -- Add this to things to be created.
	 add_atom(name)
	 if parent then
	    add_parent(name, parent)
	    typeBuilder(v, name)
	 else
	    typeBuilder(v, k)
	 end
	 
      else
	 DEBUG(name .. ' description '  .. '=' .. v)
	 -- Instance Handling:
	 table.insert(instances, k )
      end
   end
end

-- Creates containers.
function containerBuilder(containers, parent)
   for k,v in pairs(containers) do
      local name = tostring(k).lower(k)
      if (type(v) == "table") then
	 --call helper? or somehow associate this shit.
	 if parent then
	    add_room(name, name, v or "A non-descript container")
	    containerBuilder(v, name) -- Recursive call, create portals while you're at it.
	 end
      end
   end
end


-- Links to rooms.
function portalBuilder()
   --Iterate through PORTALS field of .lua file, create define portal exits.
   --Since portals are just things, create one in the room, and set portal.exit to parent's room.id.
   --Remember, that portals can be doors and shit, since it's just a thing.

end

-- Uses add_thing to create instances of stuff in the game. Doesn't really do anything else. At this point, the muderator needs to make stuff
--[[ Don't like this function, because it creates things and doesn't really tell them where to go. It'd be more beneficial to create instances of CONTAINERS, and place THINGS inside them. 
function instanceBuilder(instances)
   for k,v in pairs(instances) do
       -- Create_things has an empty list passed in, because I don't know what to do with it atm.
      table.insert(gameData, { id = create_thing(v, { }), descripton = v } )
      
   end   
end
   --]]


-- Function creator. Uses all of the values in Words to create functions for Things and Containers.
function functionBuilder()
   --TODO.
end








