--@description Reverse selected items stereo
--@author gaspard
--@version 1.0.1
--@changelog Init
--@about Reverse selected items stereo.

local item_count = reaper.CountSelectedMediaItems(0)
if item_count < 1 then return end

local items = {}

-- Get all selected items
for i = 1, item_count do
    local item = reaper.GetSelectedMediaItem(0, i - 1)
    items[i] = item
end

reaper.Undo_BeginBlock()

-- Clear selction of all items
reaper.Main_OnCommand(40289, 0)

-- Reverse stereo channels
for i, item in ipairs(items) do
    reaper.SetMediaItemSelected(item, true)

    local take = reaper.GetMediaItemTake(item, 0)
    local chan_mode = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")

    if chan_mode == 0 then
        reaper.Main_OnCommand(40177, 0)
    elseif chan_mode == 1 then
        reaper.Main_OnCommand(40176, 0)
    end

    reaper.SetMediaItemSelected(item, false)
end

-- Re select all originaly selected items
for i, item in ipairs(items) do
    reaper.SetMediaItemSelected(item, true)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Reversed selected items stereo channels.", -1)
