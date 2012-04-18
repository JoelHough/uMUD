require'functional'
require'types'
require'functions'

add_atoms{'bind-modes', [{'and', 'except'}]='noun-preposition'}

-- Bind-modes:
-- none = Do not bind.  The whole noun_group is used as an argument
-- standard = Everything reachable in the room or any open containers(recursive) in the room, then player's inventory[, then other's inventory?].  Passes an object from things
-- inventory = Player's inventory only. Passes an object from things.

add_function('bind-modes', {subject='standard', object='standard'})

function get_objects_from_phrase(container, phrase)
   if not container then return {} end
   -- For each group, modify a selected item list using world queries
   -- Example: the treasure and weapons except the rusty stuff and the green dirk
   -- Keep this handy: http://en.wikipedia.org/wiki/Logical_connective

   -- Precedence: not, and, or
   -- note: TODO: People often interchange and/or.  Do we really need or (as in pick one at random)?
   -- except, but = and not()
   -- note: TODO: characters are technically things!  this probably isn't what players expect. Think about that.
   -- match-alls (things only!): everything things stuff ones items
   -- TODO: Strings (as opposed to pronouns and nouns) make no sense here.  Probably an error condition.
   -- TODO: The parser can probably make our job easier.  Apply logic order there?
   --[[ I wish I could bind...
      everything except the blue one
      20 dirks
      dirks in the box]]

   local items = {}
   for _, group in ipairs(phrase.groups) do
      local preposition = group.preposition or 'and' -- No preposition? Probably the first group. Assume 'and'
      -- TODO: simplify prepositions for this next part.  we only handle a couple of base words
      -- This is a stupid version.  Any preposition that is and-like adds anything that matches in the container to the list
      -- Any but-like remove anything in the list so far that matches.  Complicated expression are lost on this binder.
      -- and -> items += search_container(container, noun|pronoun, adjectives)
      -- but -> items -= search_list(items, noun|pronoun, adjectives)
      if group.noun then
         local types = group.adjectives
         table.insert(types, group.noun)
         if preposition == 'and' then
            for _, v in ipairs(container.contents) do -- This should use a function for container searching or something
               if types_match( {v.type} , types) then table.insert(items, v) end
            end
         elseif preposition == 'except' then
            for i=#items, 1, -1 do
               if types_match( { items[i].type }, types) then table.remove(items, i) end
            end
         end
      elseif group.pronoun then
         if preposition == 'and' then
            for _, v in ipairs(container.contents) do
               if v.name:lower() == group.pronoun:lower() then table.insert(items, v) end
            end
         elseif preposition == 'except' then
            for i=#items, 1, -1 do
               if items[i].name:lower() == group.pronoun:lower() then table.remove(items, i) end
            end
         end
      end
   end
   local results = {}
   for i, v in ipairs(table.unique(items)) do
      results[i] = {types=v.types, value=v}
   end
   return results
end

function types_match(types, adjectives)
   -- Each adjective must be a parent of at least one type.
   return all(adjectives, function (adj) return any(types, bind2(is_child_of, adj)) end)
end

local function group_item(group)
   return group.noun or group.pronoun or (group.string and 'string-type') or (group.thing_id and 'thing-id')
end

local function bind_phrase(thing, phrase, bind_mode)
   DEBUG('Bind mode is ' .. bind_mode)
   if not phrase then return nil end
   local results = {}
   if bind_mode == 'none' then
      for _, group in ipairs(phrase.groups) do
         table.insert(results, {type=group_item(group), value=group})
      end
   elseif bind_mode == 'standard' then
      results = get_objects_from_phrase(thing.container, phrase)
   elseif bind_mode == 'inventory' then
      results = get_objects_from_phrase(thing.contents, phrase)
   end

   return results
end

local function huh(...)
   print('I don\'t know how to do that.')
end

local function safe_f(f)
   local f = get_function(f)
   if type(f) ~= 'function' then
      DEBUG'Unknown function'
      return huh
   else
      return f
   end
end

function bind_and_execute(actor, command)
   DEBUG('Binding and executing command from ' .. actor.name)
   local verb = modified_verb(command.verb, command.preposition, command.adverbs)
   DEBUG('Verb is \'' .. verb .. '\'')
   if not get_atom(verb) then
      -- The verb coming in has been vetted already, so only the preposition form is invalid
      print('I don\'t know how to ' .. command.verb .. ' things ' .. command.preposition .. ' stuff.')
      return nil
   end

   local bind_modes = F{'bind-modes', verb}
   printTable(bind_modes)
   local subjects = bind_phrase(actor, command.subject, bind_modes.subject)
   local objects = bind_phrase(actor, command.object, bind_modes.object)

   if not subjects then
      DEBUG'Bare verb'
      safe_f{actor.types, verb}(player, verb)
   elseif not objects then
      DEBUG('Bound ' .. #subjects .. ' subjects')
      if #subjects == 0 then
         print('Couldn\'t find anything by that description')
      else
         for _, subject in pairs(subjects) do
            safe_f{actor.types, verb, subject.types}(actor, verb, subject.value)
         end
      end
   else
      DEBUG('Bound ' .. #subjects .. ' subjects and ' .. #objects .. ' objects')
      if #subjects == 0 or #objects == 0 then
         print('Couldn\'t find anything by that description')
      else
         for _, subject in pairs(subjects) do
            for _, object in pairs(objects) do
               safe_f{actor.types, verb, subject.types, object.types}(actor, verb, subject.value, object.value)
            end
         end
      end
   end
end