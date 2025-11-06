--@description Select previous folder track keeping selection
--@author gaspard
--@version 1.0.1
--@changelog Consider only visible tracks
--@about Select previous folder track keeping selection.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

local function ParentCollapsed(track)
    local collapsed = false
    local parent = reaper.GetParentTrack(track)

    while parent do
        if reaper.GetMediaTrackInfo_Value(parent, "I_FOLDERCOMPACT") == 2 then
            collapsed = true
            break
        end
        parent = reaper.GetParentTrack(parent)
    end

    return collapsed
end

local track = reaper.GetSelectedTrack(0, 0)
local index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 2

while index >= 0 do
    local cur_track = reaper.GetTrack(0, index)

    if reaper.GetMediaTrackInfo_Value(cur_track, "B_SHOWINTCP") == 1 and reaper.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH") == 1 then
        if not ParentCollapsed(cur_track) then
            reaper.SetTrackSelected(cur_track, true)
            break
        end
    end

    index = index - 1
end

reaper.UpdateArrange()

