function table.find(t, val)
   for k, v in pairs(t) do
      if v == val then return k end
   end
   return nil
end

function rtrim(s)
   return s:gsub("^(.-)%s$", "%1")
end

function trim(s)
   -- from PiL2 20.4
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

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


