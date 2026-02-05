--@description Toggle solo on track under mouse cursor exclusive
--@author gaspard
--@version 1.0.1
--@changelog UI Refresh upgrade
--@about Toggle solo on track under mouse cursor exclusive.

local x, y = reaper.GetMousePosition()
local track, info = reaper.GetTrackFromPoint(x, y)
if not track or info ~= 0 then return end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40340, 0) -- Track: Unsolo all tracks

if reaper.GetMediaTrackInfo_Value(track, "I_SOLO") == 0 then
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 2)
else
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
end

reaper.Undo_EndBlock("Toggle solo on track under mouse cursor exclusive", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
