require'functional'
require'types'

function get_objects_from_phrase(container, phrase)
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

   local items = {}
   for _, group in ipairs(phrase.groups) do
      local preposition = group.preposition or 'and' -- No preposition? Probably the first group. Assume 'and'
      -- TODO: simplify prepositions for this next part.  we only handle a couple of base words
      
      -- This is a stupid version.  Any preposition that is and-like adds anything that matches in the container to the list
      -- Any but-like remove anything in the list so far that matches.  Complicated expression are lost on this binder.
      -- and -> items += search_container(container, noun|pronoun, adjectives)
      -- but -> items -= search_list(items, noun|pronoun, adjectives)
   end      
   return items
end

function types_match(types, atoms)
   -- Each type must be a child of at least one atom.
   return all(types, compose(bind1(any, atoms), curry(is_child_of))
end