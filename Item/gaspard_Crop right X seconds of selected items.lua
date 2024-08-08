--@description Crop right X seconds of selected items
--@author gaspard
--@version 0.1
--@changelog Script creation
--@about Crops right of selected items (X seconds through user input)

-- GET INPUTS FROM USER --
function InputDatas()
    defaultDatas = "0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Crop selected items from right", 1, "Seconds to crop =", defaultDatas)
    if isNotCanceled == true then
        seconds_crop = retvals_csv:match("(.+)")
        seconds_crop = seconds_crop + 0
        CropItems()
    end
end

-- CROP SELECTED ITEMS --
function CropItems()
    error_list = {}
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if length > seconds_crop then
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length - seconds_crop)
        else
            position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            table.insert(error_list, position)
        end
    end
    
    if #error_list ~= 0 then
        reaper.MB("There are "..tostring(#error_list).." items too short to crop this much", "WARNING", 0)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
reaper.ClearConsole()
if reaper.CountSelectedMediaItems(0) ~= 0 then
    InputDatas()
else
    reaper.MB("Please selecte at least one item.", "WARNING", 0)
end
reaper.Undo_EndBlock("Croped selected items "..tostring(seconds_crop).." seconds from right", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

