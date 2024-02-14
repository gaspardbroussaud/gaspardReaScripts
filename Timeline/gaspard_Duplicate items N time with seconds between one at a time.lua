--@description Duplicate items N times with seconds between one at a time
--@author gaspard
--@version 1.0
--@changelog
--Initial release
--@about
--    Duplicates selection of items N times with X seconds between copies, one item at a time.

-- GET INPUTS FROM USER --
function inputDatas()
    defaultDatas = "1,1"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Duplicate items data", 2, "Number of copies = ,Seconds between copies = ", defaultDatas)
    if isNotCanceled == true then
        tempNval,tempSecondsVal = retvals_csv:match("(.+),(.+)")
        Nval = math.tointeger(tempNval)
        secondsVal = math.tointeger(tempSecondsVal)
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
    itemLength = reaper.GetMediaItemInfo_Value(itemTab[0], "D_LENGTH")
    if Nval == 0 then
        totalLength = itemLength + secondsVal
    else
        totalLength = Nval * (itemLength + secondsVal)
    end
    reaper.SetMediaItemSelected(itemTab[0], false)
    reaper.ApplyNudge(0, 0, 0, 1, totalLength, false, 0)
    
    for i in ipairs(itemTab) do
        reaper.SetMediaItemPosition(itemTab[i], itemStart + ((itemLength + secondsVal) * (Nval + 1)), false)
        itemStart = reaper.GetMediaItemInfo_Value(itemTab[i], "D_POSITION")
        itemLength = reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH")
        totalLength = Nval * (itemLength + secondsVal)
        reaper.SetMediaItemSelected(itemTab[i], false)
        reaper.ApplyNudge(0, 0, 0, 1, totalLength, false, 0)
    end
end

function duplicateItems()
    
    for i in ipairs(itemTab) do
        reaper.SetMediaItemSelected(itemTab[i], false) --Unselect all items
    end
    
    reaper.SetMediaItemSelected(itemTab[0], true) --Select first item
    itemLength = reaper.GetMediaItemInfo_Value(itemTab[0], "D_LENGTH") --Get length of first item
    nudgeLength = itemLength + secondsVal --Get nudge length
    reaper.ApplyNudge(0, 0, 5, 1, nudgeLength, 0, Nval) --Duplicate in seconds by nudge length
    reaper.SetMediaItemSelected(itemTab[0], false) --Unselect first item

    for i in ipairs(itemTab) do
        reaper.SetMediaItemSelected(itemTab[i], true) --Select current i index item
        itemLength = reaper.GetMediaItemInfo_Value(itemTab[i], "D_LENGTH") --Get current i item length
        nudgeLength = itemLength + secondsVal --Get nudge length
        reaper.ApplyNudge(0, 0, 5, 1, nudgeLength, 0, Nval) --Duplicate in seconds by nudge length
        reaper.SetMediaItemSelected(itemTab[i], false) --Unselect current i index item
    end
end

-- MAIN EXECUTION --
reaper.Undo_BeginBlock()
sel_item_count = reaper.CountSelectedMediaItems(0)
if sel_item_count ~= 0 then
    reaper.ClearConsole()
    inputDatas()
    if isNotCanceled == true then
        addItemsToTab()
        setNewItemPos()
        if Nval ~= 0 then
            duplicateItems()
        end
    end
    if Nval == 0 and sel_item_count == 1 then
        reaper.MB("Since only one item is selected and copies number is 0, nothing happens.", "Nothing happens", 0)
        reaper.SetMediaItemSelected(itemTab[0], true)
    end
else
    reaper.MB("Please select at least one item", "No item selected", 0)
end
reaper.Undo_EndBlock("Duplicates item N times with X seconds between each at a time", 0)
