--@description Add space between each selected items
--@author gaspard
--@version 1.0.0
--@changelog initial release 
--@about Add space between each selected items.

-- GET USER INPUTS
function InputDatas()
    local datas = "0"
    local isNotCanceled, retvals_csv = reaper.GetUserInputs("Add space between items (seconds)", 1, "Space =", datas)
    if isNotCanceled == true then
        local start_pos, end_pos = retvals_csv:find(",", 1)
        if not start_pos then
            local space = retvals_csv:match("(.+)")
            SetNewItemPos(space)
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
function SetNewItemPos(space)
    local items = AddItemsToTab()
    reaper.SetMediaItemSelected(items[0], false)

    for i = 1, #items do
        local cur_start = reaper.GetMediaItemInfo_Value(items[i], "D_POSITION")

        local new_start = cur_start + space
        reaper.SetMediaItemPosition(items[i], new_start, false)
        reaper.SetMediaItemSelected(items[i], false)
        reaper.ApplyNudge(0, 0, 0, 1, space, false, 0)
    end

    for i = 0, #items do
        reaper.SetMediaItemSelected(items[i], true)
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
reaper.Undo_EndBlock("Add space between each selected items", -1)
