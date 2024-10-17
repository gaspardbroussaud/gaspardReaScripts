--@description Set marker to first transient in selected items
--@author gaspard
--@version 1.0.0
--@changelog Initial release
--@about Set marker to first transient in selected items

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local item_count = reaper.CountSelectedMediaItems(0)
if item_count ~= 0 then
    local items = {}
    for i = 0, item_count do
        items[i] = reaper.GetSelectedMediaItem(0, i)
    end
    
    local edit_cursor_origin = reaper.GetCursorPosition()
    
    for i = 0, #items do
        local item = items[i]
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local take = reaper.GetMediaItemTake(item, 0)
        local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        reaper.SetEditCurPos(position, false, false)
        reaper.Main_OnCommand(40836, 0) -- Item navigation: Move cursor to nearest transient in items
        local cursor_position = reaper.GetCursorPosition()
        reaper.AddProjectMarker(0, false, cursor_position, 0, name, -1)
    end
    
    reaper.SetEditCurPos(edit_cursor_origin, false, false)
else
    reaper.MB("No item(s) selected", "Message", 0)
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Set marker to first transient in selected items", -1)
