--@description Set selected items start with seconds between
--@author gaspard
--@version 1.0
--@changelog
--    Initial release.  
--@about
--    Set selected items start with seconds between.

-- GET INPUTS FROM USER --
function inputDatas()
    defaultDatas = "1"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Space items data", 1, "Seconds between items start = ", defaultDatas)
    if isNotCanceled == true then
        secondsVal = retvals_csv:match("(.+)")
    end
end

-- ADD SELECTED ITEMS TO TABLE --
function addItemsToTab()
    itemTab = { }
  
    for i = 0, sel_item_count - 1 do
        itemTab[i] = reaper.GetSelectedMediaItem(0, i)
    end
end

-- SETS ITEM POS WITH SPACE FOR DUPLICATION AND SECONDS BETWEEN --
function setNewItemPos()
    itemStart = reaper.GetMediaItemInfo_Value(itemTab[0], "D_POSITION")

    reaper.SetMediaItemSelected(itemTab[0], false)
    reaper.ApplyNudge(0, 0, 0, 1, secondsVal, false, 0)
    
    for i in ipairs(itemTab) do
        reaper.SetMediaItemPosition(itemTab[i], itemStart + secondsVal, false)
        itemStart = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        reaper.SetMediaItemSelected(itemTab[i], false)
        reaper.ApplyNudge(0, 0, 0, 1, secondsVal, false, 0)
    end
end

function main()
    sel_item_count = reaper.CountSelectedMediaItems(0)
    if sel_item_count ~= 0 then
        inputDatas()
        if isNotCanceled == true then
            addItemsToTab()
            setNewItemPos()
        end
    else
        reaper.MB("Please select at least one item", "No item selected", 0)
    end
end

-- MAIN EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Duplicates item N times with X seconds between each at a time", 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
