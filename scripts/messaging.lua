local function name_replace(text, name, with)
   return (text .. ' '):gsub('(%A)' .. name .. '(%A)', '%1' .. with .. '%2'):sub(1, -2)  -- Dirty space hack to sub at edges
end

function player_text(player, text)
   local player_name = M('name', player)
   server_send(player_name, name_replace(text, player_name, 'yourself'))
end

function witness_text(player, text)
   local player_name = M('name', player)
   local container = M('container', player)
   for _, witness in ipairs(bind_from_container(container, parse_phrase('player except ' .. player_name))) do
      printTable(witness, DEBUG)
      local witness_name = M('name', witness.value)
      server_send(witness_name, name_replace(text, witness_name, 'you'))
   end
end