--@description Crop item left and right edges with next selected item length (using timeline position)
--@author gaspard
--@version 1.0.1
--@changelog Script creation
--@about Crops left and right edges of selected item with next selected item's length (using timeline position to set length).

local function SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

local function CheckSelectedItem(previous_item)
    local next_item = reaper.GetSelectedMediaItem(0, 0)
    if previous_item ~= next_item then
        return true, next_item, previous_item
    end
    return false, previous_item, previous_item
end

local function CropItem(previous_item, model)
    reaper.Undo_BeginBlock()
    local start_pos = reaper.GetMediaItemInfo_Value(model, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(model, "D_LENGTH")

    local take = reaper.GetActiveTake(previous_item)
    local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local old_start_pos = reaper.GetMediaItemInfo_Value(previous_item, "D_POSITION")
    local position_distance = math.abs(start_pos - old_start_pos)

    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", take_offset + position_distance)
    reaper.SetMediaItemInfo_Value(previous_item, "D_LENGTH", length)
    reaper.SetMediaItemInfo_Value(previous_item, "D_POSITION", start_pos)

    reaper.Undo_EndBlock("Crop item left and right edges", -1)
    reaper.UpdateArrange()
end

local function Loop()
    done, item, previous_item = CheckSelectedItem(item)
    if reaper.CountSelectedMediaItems(0) ~= 1 then return end
    if not done then reaper.defer(Loop)
    else CropItem(previous_item, item) end
end

local function Main()
    item = reaper.GetSelectedMediaItem(0, 0)
    if item then
        SetButtonState(1)
        Loop()
    end
end

item = nil
Main()
reaper.atexit(SetButtonState)
