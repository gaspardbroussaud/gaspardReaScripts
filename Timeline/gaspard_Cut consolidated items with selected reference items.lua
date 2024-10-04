-- @description Cut consolidated items with selected reference items
-- @author gaspard
-- @version 1.1.1
-- @changelog Fix no cutting at end of item if only one item is selected.
-- @about Cuts items with selected reference items. For Post-production use.

-- CREATE TABLE OF SELECTED ITEMS --
function createItemTab()
    itemTab = {}
    
    for i = 0, sel_item_count - 1 do
        itemTab[i] = reaper.GetSelectedMediaItem(0, i) -- Get all selected items to table
    end
    
    for i = 0, #itemTab do
        reaper.SetMediaItemSelected(itemTab[i], false) -- Unselect all items in table
        reaper.UpdateArrange()
    end
end

-- SET VARIABLES FOR COLLIDE CHECK --
function setupVariables()
    cur_item_start = reaper.GetMediaItemInfo_Value(itemTab[0], "D_POSITION")
    cur_item_length = reaper.GetMediaItemInfo_Value(itemTab[0], "D_LENGTH")
    cur_item_end = cur_item_start + cur_item_length
    
    reaper.SetEditCurPos(cur_item_start, false, false) -- Set edit cursor to cut items
    reaper.Main_OnCommand(40757, 0) -- Cut all items at edit cursor
    
    prev_item_end = cur_item_end
end

-- CUT ITEM WITH SELECTED ITEM LENGTH --
function cutConsolidatedItem()
    
    setupVariables()
    
    for i = 0, #itemTab do
        cur_item_start = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        cur_item_length = reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH")
        cur_item_end = cur_item_start + cur_item_length
        
        if prev_item_end + 0.0000001 < cur_item_start then -- Checks if there ia gap between previous and current items
            reaper.SetEditCurPos(prev_item_end, false, false) -- Set edit cursor to cut items
            reaper.Main_OnCommand(40757, 0) -- Cut all items at edit cursor
        end
        
        if i == #itemTab then --Checks if it is the end of the table
            reaper.SetEditCurPos(cur_item_end, false, false) -- Set edit cursor to cut items
            reaper.Main_OnCommand(40757, 0) -- Cut all items at edit cursor
        end
        
        reaper.SetEditCurPos(cur_item_start, false, false) -- Set edit cursor to cut items
        reaper.Main_OnCommand(40757, 0) -- Cut all items at edit cursor
        
        prev_item_end = cur_item_end
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
reaper.Undo_EndBlock("Cut item to selected reference items", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
