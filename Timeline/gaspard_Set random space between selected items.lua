--@description Set random space between selected items
--@author gaspard
--@version 1.0.0
--@changelog initial release 
--@about Set random space between selected items.

-- GET USER INPUTS
function InputDatas()
    local datas = "0,1"
    local isNotCanceled, retvals_csv = reaper.GetUserInputs("Set space between (seconds)", 2, "Min = ,Max = ", datas)
    if isNotCanceled == true then
        local count = 0
        local start_pos = 1
        local end_pos = 2
        while true do
            start_pos, end_pos = retvals_csv:find(",", start_pos)
            if not start_pos or count > 1 then break end
            count = count + 1
            start_pos = end_pos + 1
        end
        if count == 1 then
            local min, max = retvals_csv:match("(.+),(.+)")
            SetNewItemPos(min, max)
        else
            reaper.MB("Please write numbers with dots.", "Message", 0)
        end
    end
end

-- ADD SELECTED ITEMS TO TABLE
function AddItemsToTab()
    local items = { }

    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        items[i] = reaper.GetSelectedMediaItem(0, i)
    end

    return items
end

-- SET ITEMS POSITION WITH RANDOM
function SetNewItemPos(min, max)
    local items = AddItemsToTab()

    local item_start = reaper.GetMediaItemInfo_Value(items[0], "D_POSITION")
    local item_length = reaper.GetMediaItemInfo_Value(items[0], "D_LENGTH")

    for i = 1, #items do
        local random_value = min + (max - min) * math.random()

        reaper.SetMediaItemPosition(items[i], item_start + item_length + random_value, false)

        item_start = reaper.GetMediaItemInfo_Value(items[i], "D_POSITION")
        item_length = reaper.GetMediaItemInfo_Value(items[i], "D_LENGTH")
    end
end

-- MAIN
function Main()
    local sel_item_count = reaper.CountSelectedMediaItems(0)
    if sel_item_count ~= 0 then
        InputDatas()
    else
        reaper.MB("Please select at least one item", "Message", 0)
    end
end

-- MAIN EXECUTION --
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Set random space between selected items", -1)
