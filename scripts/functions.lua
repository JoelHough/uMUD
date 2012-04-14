-- Functions table handling.
require('types')


functions = { }

function functions.new(string, f)
   if not functions[string] then   
      funcions[string] = f
   end
   
end

function no_function(...)
   print('I don\'t know how to do that.')
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

function get_function(verb, subject, object) --Get sword with the tongs - sword = subject, tongs = object

   local x,y,z

   x = helper(verb)
   y = helper(subject)
   z = helper(object)

   for ix,vx in ipairs(x) do

      for iy,vy in ipairs(y) do
	 for iz,vz in ipairs(z) do
	    output = vx .. vy .. vz
	    local f = functions[output:match(".*%S")]
	    if f then
	       return f
	    end

	 end
      end
   end
   return no_function
end


-- Small helper function to take in an atom (verb, subject, etc...) and return its parents in the heirarchy.
-- Should the atom be nil, meaning it wasn't supplied as an arg in get_function, it returns a table containing an empty string.
function helper(atom)
   if not atom then
      x = { }
      return { "" }
   else
      return get_all_parents(atom)
   end
end




