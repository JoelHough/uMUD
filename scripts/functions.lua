-- Functions table handling.
require'types'
require'log'
require'utils'

local functions = { }

local function new_function_(atoms, func, funcs, level)
   if #atoms < level then
      if funcs[1] then WARNING('Overriding function for \'' .. table.concat(atoms, ' ') .. "'") end
      funcs[1] = func
   else
      local atom = atoms[level]
      if not funcs[atom] then funcs[atom] = {} end
      new_function_(atoms, func, funcs[atom], level + 1)
   end
end

function new_function(atoms, func)
   if type(atoms) == 'string' then atoms = words(atoms) end
   new_function_(atoms, func, functions, 1)
end

function modified_function(verb, preposition, adverbs)
   -- Turns 'get', 'with', and {'quickly'} from 'quickly get <subject> with <object>' 
   -- into the verb 'get-with-quickly', if such a variation exists.
   -- Adverbs are optional.  No get-quickly?  get will work fine.
   -- Prepositions are not optional.  No get-with?  Then we shouldn't even try to execute this thing.

   -- Simple name-mangling is used to find function forms.
   -- First, append '-<preposition>', so 'get' becomes 'get-with'
   local new_verb = verb .. '-' .. preposition

   -- TODO: Then, we do some magic for finding verbs that are modified by adverbs.
   -- Well, we don't yet because our adverbs are just for flavor right now, and the
   -- output functions have access to the adverbs so that they can add the flavor
   -- text without the use of overloaded functions.

   -- TODO: If the verb doesn't have this particular form, we need a clever error
   -- for the user.  Something like 'I don't know how to <verb> stuff <preposition> things.
   -- So, 'I don't know how to get/hit/cuddle stuff with/using/beneath things'
   return new_verb
end

local function do_nothing(...)
   
end

local function get_function_(atoms, funcs, level)
   if #atoms < level then return funcs[1] end
   local ancestry = get_all_parents(atoms[level])
   for _, v in ipairs(ancestry) do
      local sub_funcs = funcs[v]
      if sub_funcs then
         local f = get_function(atoms, sub_funcs, level + 1) or sub_funcs[1]
         if f then return f end
      end
   end
   return nil
end

function get_function(atoms)
   if type(atoms) == 'string' then atoms = words(atoms) end
   local f = get_function_(atoms, functions, 1)
   if not f then
      WARNING('No function found for \'' .. table.concat(atoms, ' ') .. '\'.  Returning do_nothing()')
      return do_nothing
   end
   return f
end
F = get_function
