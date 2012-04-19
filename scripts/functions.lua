-- Functions table handling.
require'types'
require'log'
require'utils'

local functions = { }

local function add_function_(atoms, func, funcs, level)
   if #atoms < level then
      if funcs[1] then WARNING('Overriding function for \'' .. table.concat(atoms, ' ') .. "'") end
      funcs[1] = func
   else
      local atom = atoms[level]
      if not funcs[atom] then funcs[atom] = {} end
      add_function_(atoms, func, funcs[atom], level + 1)
   end
end

function add_function(atoms, func)
   if type(atoms) == 'string' then atoms = words(atoms) end
   add_function_(atoms, func, functions, 1)
end

function add_functions(funcs)
   for atoms, func in pairs(funcs) do
      add_function(atoms, func)
   end
end

function modified_verb(verb, preposition, adverbs)
   -- Turns 'get', 'with', and {'quickly'} from 'quickly get <subject> with <object>' 
   -- into the verb 'get-with-quickly', if such a variation exists.
   -- Adverbs are optional.  No get-quickly?  get will work fine.
   -- Prepositions are not optional.  No get-with?  Then we shouldn't even try to execute this thing.

   -- Simple name-mangling is used to find function forms.
   -- First, append '-<preposition>', so 'get' becomes 'get-with'
   local new_verb = verb
   if preposition then 
      new_verb = new_verb .. '-' .. preposition
   end

   -- TODO: Then, we do some magic for finding verbs that are modified by adverbs.
   -- Well, we don't yet because our adverbs are just for flavor right now, and the
   -- output functions have access to the adverbs so that they can add the flavor
   -- text without the use of overloaded functions.

   -- TODO: If the verb doesn't have this particular form, we need a clever error
   -- for the user.  Something like 'I don't know how to <verb> stuff <preposition> things.
   -- So, 'I don't know how to get/hit/cuddle stuff with/using/beneath things'
   return new_verb
end

local function get_function_(atoms, funcs, level, names)
   if #atoms < level then return funcs[1] end
   local ancestry = get_all_parents(atoms[level])
   for _, v in ipairs(ancestry) do
      local sub_funcs = funcs[v]
      if sub_funcs then
         local f = get_function_(atoms, sub_funcs, level + 1, names) or sub_funcs[1]
         if f ~= nil then
            table.insert(names, 1, v)
            return f
         end
      end
   end
   return nil
end

local function print_atoms(atoms)
   local string = ""
   for i, arg in ipairs(atoms) do
      if i ~= 1 then string = string .. ' ' end
      if type(arg) == 'string' then
         string = string .. arg
      elseif type(arg) == 'table' then
         string = string .. '{'
         for j, str in ipairs(arg) do
            if j ~= 1 then string = string .. ' ' end
            string = string .. str
         end
         string = string .. '}'
      end
   end
   return string
end

function get_function(atoms)
   if type(atoms) == 'string' then atoms = words(atoms) end
   for i, v in ipairs(atoms) do
      if v.types then atoms[i] = v.types end
   end
   
   local found = {}
   local f = get_function_(atoms, functions, 1, found)
   if f == nil then
      WARNING('No function found for \'' .. print_atoms(atoms) .. '\'.')
   else
      DEBUG('Found function \'' .. table.concat(found, ' ') .. '\' for \'' .. print_atoms(atoms) .. '\'')
   end
   return f
end
F = get_function
