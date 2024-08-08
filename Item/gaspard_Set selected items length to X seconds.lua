--@description Set selected items length to X seconds
--@author gaspard
--@version 0.1
--@changelog Script creation
--@about Set all selected items length to the same X seconds from user input

-- GET INPUTS FROM USER --
function InputDatas()
    defaultDatas = "0"
    isNotCanceled, retvals_csv = reaper.GetUserInputs("Set selected items new length", 1, "New length (0.01 minimum) =", defaultDatas)
    if isNotCanceled == true then
        new_length = retvals_csv:match("(.+)")
        new_length = new_length + 0
        if new_length >= 0.01 then
            CropItems()
        else
            InputDatas()
        end
    end
end

-- CROP SELECTED ITEMS --
function CropItems()
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "D_LENGTH", new_length)
    end
end

-- MAIN SCRIPT EXECUTION --
reaper.PreventUIRefresh(1)
reaper.ClearConsole()
if reaper.CountSelectedMediaItems(0) ~= 0 then
    InputDatas()
else
    reaper.MB("Please select at least one item.", "WARNING", 0)
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

