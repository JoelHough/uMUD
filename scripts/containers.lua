function move_content(content, new_container)
   if content.container then
      local from = content.container.contents
      table.remove_item(from, content)
   end
   content.container = new_container
   table.insert(new_container.contents, content)
end
