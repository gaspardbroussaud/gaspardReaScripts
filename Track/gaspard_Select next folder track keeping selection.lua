--@description Select next folder track keeping selection
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Select next folder track keeping selection.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

local track = reaper.GetSelectedTrack(0, track_count - 1)
local index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

for i = index, reaper.CountTracks(0) - 1 do
    local cur_track = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH") == 1 then
        reaper.SetTrackSelected(cur_track, true)
        break
    end
end

reaper.UpdateArrange()
