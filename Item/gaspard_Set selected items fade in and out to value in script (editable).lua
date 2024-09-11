--@description Set selected items fade in and out to value in script (editable)
--@author gaspard
--@version 1.0
--@changelog Initial release
--@about Sets fade in and out to specified values in script (editable by user) for each selected items

-- USER EDITABLE VALUES --------------------------------------
local fade_in_len = 100 -- Length of fade in (milliseconds)
local fade_out_len = 100 -- Length of fade in (milliseconds)
--------------------------------------------------------------

-- SCRIPT FUNCTIONS --
function main()
    -- Check for selected items in project --
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    if sel_item_count ~= 0 then
    
    -- Set length in milliseconds --
    fade_in_len = fade_in_len/1000
    fade_out_len = fade_out_len/1000
    
    -- Apply to all selected items --
        for i = 0, sel_item_count - 1 do
            item = reaper.GetSelectedMediaItem(0, i)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fade_in_len)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fade_out_len)
        end
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Set selected items fade in and out to value in script (editable)", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()


