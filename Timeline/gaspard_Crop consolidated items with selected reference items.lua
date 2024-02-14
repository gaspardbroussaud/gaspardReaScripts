--@description Crop consolidated items with selected reference items
--@author gaspard
--@version 1.0
--@changelog
--      Initial release
--@about
--      Crop consolidated items with selected reference items.
--      For Post-production use.

-- CREATE TABLE OF SELECTED ITEMS --
function createItemTab()
    itemTab = {}
    
    for i = 0, sel_item_count - 1 do
        itemTab[i] = reaper.GetSelectedMediaItem(0, i)
    end
    
    for i in pairs(itemTab) do
        reaper.SetMediaItemSelected(itemTab[i], false)
        reaper.UpdateArrange()
    end
end

-- CUT ITEM WITH SELECTED ITEM LENGTH --
function cutConsolidatedItem()
    for i in pairs(itemTab) do
        cur_item_start = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        cur_item_length = reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH")
        cur_item_end = cur_item_start + cur_item_length
        reaper.SetEditCurPos(cur_item_start, false, false)
        reaper.Main_OnCommand(40757, 0)
        reaper.SetEditCurPos(cur_item_end, false, false)
        reaper.Main_OnCommand(40757, 0)
    end
end

-- FUNCTION MAIN --
function main()
    sel_item_count = reaper.CountSelectedMediaItems(0)
    
    if sel_item_count ~= 0 then
        createItemTab()
        cutConsolidatedItem()
    else
        reaper.MB("Please select at least one item", "No item selected", 0)
    end
end

-- SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Crop item to selected items", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
