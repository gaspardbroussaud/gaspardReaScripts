--@description Reverse selected items stereo
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Reverse selected items stereo.

local item_count = reaper.CountSelectedMediaItems(0)
if item_count < 1 then return end

for i = 1, item_count do
    local item = reaper.GetSelectedMediaItem(0, i - 1)
    local take = reaper.GetMediaItemTake(item, 0)
    local chan_mode = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
    if chan_mode == 0 then
        reaper.Main_OnCommand(40177, 0)
    elseif chan_mode == 1 then
        reaper.Main_OnCommand(40176, 0)
    end
end

