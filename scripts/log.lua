DEBUG_ON = true

function DEBUG(s, i)
   if not DEBUG_ON then return nil end
   local info = debug.getinfo(2 + (i or 0))
   print(info.source .. ':' .. info.currentline .. ':' .. s)
end