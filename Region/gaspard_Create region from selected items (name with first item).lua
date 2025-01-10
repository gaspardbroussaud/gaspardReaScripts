--@description Create region from selected items (name with first item)
--@author gaspard
--@version 1.0
--@changelog
--  - Script added
--@about
--  - Create region from selected items (name with first item)

local item_count = reaper.CountSelectedMediaItems(0)
if item_count > 0 then
    local first_item = reaper.GetSelectedMediaItem(0, 0)
    local last_item = reaper.GetSelectedMediaItem(0, item_count - 1)
    local start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    local end_pos = reaper.GetMediaItemInfo_Value(last_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(last_item, "D_LENGTH")
    local _, name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(first_item), "P_NAME", "", false)

    reaper.AddProjectMarker(0, true, start_pos, end_pos, name, -1)
end
