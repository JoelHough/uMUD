--********************************************************************
--Written for cs3505 spring2012 by: Team Exception: cody curtis, joel hough, bailey malone, james murdock, john wells.
--*********************************************************************

function remove_content(content)
   if content.container then
      local from = content.container.contents
      table.remove_item(from, content)
   end
   content.container = nil
end

function move_content(content, new_container)
   remove_content(content)
   content.container = new_container
   table.insert(new_container.contents, content)
end
