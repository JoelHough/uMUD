local function name_replace(text, name, with)
   return (' ' .. text .. ' '):gsub('(%A)' .. name .. '(%A)', '%1' .. with .. '%2'):sub(2, -2)  -- Dirty space hack to sub at edges
end

function player_text(player, text)
   server_send(player.name, name_replace(text, player.name, 'yourself'))
end

function witness_text(player, text)
   for _, witness in ipairs(get_objects_from_phrase(player.container, parse_phrase('player except ' .. player.name))) do
      server_send(witneww.name, name_replace(text, witness.name, 'you'))
   end
end