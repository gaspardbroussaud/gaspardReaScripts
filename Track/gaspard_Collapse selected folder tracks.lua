--@description Collapse selected folder tracks
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Collapse selected folder tracks.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

--[[reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 1, track_count do
    local track = reaper.GetSelectedTrack(0, i - 1)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 2)
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Uncollapsed all selected tracks.", -1)
reaper.UpdateArrange()
]]

local function UnselectChildren(track)
    local index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local max_track = reaper.CountTracks(0)
    local depth = reaper.GetTrackDepth(track)
    for i = index, max_track do
        local cur_track = reaper.GetTrack(0, i)
        if not cur_track then break end
        local cur_depth = reaper.GetTrackDepth(cur_track)
        if cur_depth <= depth then break end

        reaper.SetTrackSelected(cur_track, false)
    end
end

local tracks = {}
local folders = {}
for i = 1, track_count do
    local track = reaper.GetSelectedTrack(0, i - 1)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") < 2 then
            folders[#folders + 1] = track
        else
            tracks[#tracks + 1] = track
        end
    elseif #folders < 1 then
        tracks[#tracks + 1] = track
    end
end

if #folders > 0 then
    tracks = {}
    for i, track in ipairs(folders) do
        UnselectChildren(track)
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 2)
    end
else
    local track = tracks[#tracks]
    local parent = reaper.GetParentTrack(track)
    if parent then
        reaper.SetOnlyTrackSelected(parent)
    end
end

reaper.UpdateArrange()
