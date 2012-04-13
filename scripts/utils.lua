function rtrim(s)
   return s:gsub("^(.-)%s$", "%1")
end

function trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function printTable(t)
    function printTableHelper(t, spacing)
        for k,v in pairs(t) do
            if (type(v) == "table") then
               print(spacing..tostring(k))
               printTableHelper(v, spacing.."  ")
               --print(spacing..'} //' .. tostring(k))
            else
               print(spacing..tostring(k) .. '=' .. v)
            end
        end
    end
    printTableHelper(t, "");
end
