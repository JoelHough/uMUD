--********************************************************************
--Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
--*********************************************************************

local levels = {'DEBUG', 'INFO', 'WARNING', 'ERROR', 'TEST'}
log_level = levels[1]

function locals(...)
   local locals = {}
   local i = 1
   while true do
      local k, v = debug.getlocal(2, i)
      if not k then break end
      locals[k] = v
      i = i + 1
   end

   local result_table = {}
   for i=1,select('#', ...) do
      local name = select(i, ...)
      result_table[i] = name .. '=' .. locals[select(i, ...)]
   end
   return table.concat(result_table, ', ')
end

local function log_with_source(level, message, stack_offset)
   for _, v in ipairs(levels) do
      if v == log_level then
         break
      elseif v == level then
         return
      end
   end
   local info = debug.getinfo(2 + (stack_offset or 0))
   print(level .. ':' .. info.source .. ':' .. info.currentline .. ':' .. message)
end

local function register_leveled_log(level)
   if _G[level] then
      print('Error setting up logger.  Global value already set! ' .. level)
      return nil
   end

   _G[level] = function(text) log_with_source(level, text, 1) end
end

for _, level in pairs(levels) do
   register_leveled_log(level)
end
