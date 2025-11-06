--@description Select previous folder track keeping selection
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Select previous folder track keeping selection.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

local track = reaper.GetSelectedTrack(0, 0)
local index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 2

while index > 0 do
    local cur_track = reaper.GetTrack(0, index)

    if reaper.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH") == 1 then
        reaper.SetTrackSelected(cur_track, true)
        break
    end

    index = index - 1
end

reaper.UpdateArrange()
