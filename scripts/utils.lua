function table.reverse_value_string(t, sep)
   local result = ''
   if #t > 0 then
      result = t[#t]
      for i = #t - 1, 1, -1 do
         result = result .. (sep or ' ') .. t[i]
      end
   end
   return result
end

function table.find(t, val)
   for k, v in pairs(t) do
      if v == val then return k end
   end
   return nil
end

function words(str)
   local result = {}
   for word in str:gmatch('[^ ]+') do
      table.insert(result, word)
   end
   return result
end

function rtrim(s)
   return s:gsub("^(.-)%s$", "%1")
end

function trim(s)
   -- from PiL2 20.4
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- From TableUtils
function table.count(tt, item)
  local count
  count = 0
  for ii,xx in pairs(tt) do
    if item == xx then count = count + 1 end
  end
  return count
end
function table.unique(tt)
  local newtable
  newtable = {}
  for ii,xx in ipairs(tt) do
    if(table.count(newtable, xx) == 0) then
      newtable[#newtable+1] = xx
    end
  end
  return newtable
end

-- From http://stackoverflow.com/questions/4934100/get-nested-table-result-in-lua
function printTable(t, print_func)
   local f = print_func or print
   function printTableHelper(t, spacing)
      for k,v in pairs(t) do
         if (type(v) == "table") then
            f(spacing..tostring(k))
            printTableHelper(v, spacing.."  ")
            --f(spacing..'} //' .. tostring(k))
         else
            f(spacing..tostring(k) .. '=' .. v)
         end
      end
   end
   printTableHelper(t, "");
end


