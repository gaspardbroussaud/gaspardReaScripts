--@description Toggle mute on track under mouse cursor
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Toggle mute on track under mouse cursor.

local x, y = reaper.GetMousePosition()
local track, info = reaper.GetTrackFromPoint(x, y)
if not track or info ~= 0 then return end

if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 0 then
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
else
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
end