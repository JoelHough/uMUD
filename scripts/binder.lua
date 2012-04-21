require'functional'
require'types'
require'functions'

add_atoms{[{'and', 'except'}]='noun-preposition'}

-- Bind-search values:
-- none = Do not bind.  The whole noun_group is used as an argument
-- room = Everything reachable in the room or any open containers(recursive) in the room, then player's inventory[, then other's inventory?].  Passes an object from things
-- inventory = Player's inventory only. Passes an object from things.
-- global = Everything in the game

-- Bind-limit values:
-- any = Do no limit bound values
-- single = Only one object.  If more would bind, prompt them to be more specific
add_functions{
   ['object-bind-search'] = 'room',
   ['object-bind-limit'] = 'any',
   ['subject-bind-search'] = 'room',
   ['subject-bind-limit'] = 'any',
             }

function bind_from_container(container, phrase)
   if not container then return {} end
   return bind_from_list(container.contents, phrase)
end

function bind_from_list(thing_list, phrase)
   DEBUG('Things: ' .. #thing_list)
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
            for _, v in pairs(thing_list) do -- This should use a function for container searching or something
               if types_match(v.types , types) then table.insert(items, v) end
            end
         elseif preposition == 'except' then
            for i=#items, 1, -1 do
               if types_match(items[i].types, types) then table.remove(items, i) end
            end
         end
      elseif group.pronoun then
         if preposition == 'and' then
            for k, v in pairs(thing_list) do
               -- TODO: Fancy pronoun matching for things like 'it', 'him'
               if (v.id and (v.id:lower() == group.pronoun:lower())) or
                  (v.name and (v.name:lower() == group.pronoun:lower())) then
                  table.insert(items, v)
               end
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
   DEBUG('Bound count: ' .. #results)
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
         table.insert(results, {types={group_item(group)}, value=group})
      end
   elseif bind_mode == 'global' then
      results = bind_from_list(F{'everything'}, phrase)
   elseif bind_mode == 'room' then
      results = bind_from_container(thing.container, phrase)
   elseif bind_mode == 'inventory' then
      results = bind_from_container(thing, phrase)
   end

   return results
end

local function huh(player, ...)
   player_text(player, 'I don\'t know how to do that.')
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
      player_text(actor, 'I don\'t know how to ' .. command.verb .. ' things ' .. command.preposition .. ' stuff.')
      return nil
   end

   local subjects = bind_phrase(actor, command.subject, F{'subject-bind-search', verb})
   local objects = bind_phrase(actor, command.object, F{'object-bind-search', verb})

   if not subjects then
      DEBUG'Bare verb'
      safe_f{actor.types, verb}(actor)
   elseif not objects then
      DEBUG('Bound ' .. #subjects .. ' subjects')
      if #subjects == 0 then
         player_text(actor, 'Couldn\'t find anything by that description')
      elseif #subjects > 1 and F{'subject-bind-limit', verb} == 'single' then
         player_text(actor, 'Which one?  Please be more specific.  There are ' .. #subjects .. ' of those here.')
         return nil
      else
         for _, subject in pairs(subjects) do
            safe_f{actor.types, verb, subject.types}(actor, subject.value)
         end
      end
   else
      DEBUG('Bound ' .. #subjects .. ' subjects and ' .. #objects .. ' objects')
      if #subjects == 0 or #objects == 0 then
         player_text(actor, 'Couldn\'t find anything by that description')
      elseif (#subjects > 1 and F{'subject-bind-limit', verb} == 'single') or (#objects > 1 and F{'object-bind-limit', verb} == 'single') then
         player_text(actor, 'Which one?  Please be more specific.')
         return nil
      else
         for _, subject in pairs(subjects) do
            for _, object in pairs(objects) do
               safe_f{actor.types, verb, subject.types, object.types}(actor, subject.value, object.value)
            end
         end
      end
   end
end