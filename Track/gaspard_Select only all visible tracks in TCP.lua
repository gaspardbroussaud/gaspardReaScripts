--@description Select only all visible tracks in TCP
--@author gaspard
--@version 1.0.1
--@changelog Fix selection of tracks in collapsed folder
--@about Select only all visible tracks in TCP.

local track_count = reaper.CountTracks(0)
if track_count < 1 then return end

local function AreParentsOpen(track)
    local collapsed = true
    local parent = reaper.GetParentTrack(track)
    while parent do
        if reaper.GetMediaTrackInfo_Value(parent, "I_FOLDERCOMPACT") == 2 then
            collapsed = false
            break
        end
        parent = reaper.GetParentTrack(parent)
    end
    return collapsed
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 1, track_count do
    local track = reaper.GetTrack(0, i - 1)
    local visible = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") > 0 and AreParentsOpen(track) or false
    reaper.SetTrackSelected(track, visible)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Selected all tracks.", -1)
reaper.UpdateArrange()
