--@description Collapse selected folder tracks or move selection up one folder
--@author gaspard
--@version 1.0.1
--@changelog Fix max track count
--@about Collapse selected folder tracks or move selection up one folder.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

local function UnselectChildren(track)
    local index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local max_track = reaper.CountTracks(0)
    local depth = reaper.GetTrackDepth(track)
    for i = index, max_track - 1 do
        local cur_track = reaper.GetTrack(0, i)
        if not cur_track then break end
        local cur_depth = reaper.GetTrackDepth(cur_track)
        if cur_depth <= depth then break end

        reaper.SetTrackSelected(cur_track, false)
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local undo_text = "Collapsed selected folder tracks."

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
        undo_text = "Move selection up one folder."
        reaper.SetOnlyTrackSelected(parent)
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(undo_text, -1)
reaper.UpdateArrange()
