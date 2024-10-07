--@noindex
--@description Display selected items count under mouse
--@author gaspard
--@version 1.0
--@changelog
--    Initial release
--@about
--    Display selected items count under mouse cursor.

item_count = reaper.CountSelectedMediaItems(0)
text = "Number of selected items: "..tostring(item_count)

function Show_Tooltip(text)
    local x, y = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

if item_count == 0 then
    Show_Tooltip("\n\n no selected items \n\n")
else
    Show_Tooltip("\n\n "..text.."\n\n")
end
