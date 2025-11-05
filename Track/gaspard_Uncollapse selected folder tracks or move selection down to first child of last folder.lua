--@description Uncollapse selected folder tracks or move selection down to first child of last folder
--@author gaspard
--@version 1.0.1
--@changelog Change behaviour to select first parent track in current folder if it exists
--@about Uncollapse selected folder tracks or move selection down to first child of last folder.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local undo_text = "Uncollapsed selected folder tracks."

local tracks = {}
local folders = {}
for i = 1, track_count do
    local track = reaper.GetSelectedTrack(0, i - 1)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2 then
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
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)
    end
else
    local track = tracks[#tracks]
    local parent = reaper.GetParentTrack(track)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        parent = track
    end
    if parent then
        local index = reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER")
        local depth = reaper.GetTrackDepth(parent)
        for i = index, reaper.CountTracks(0) - 1 do
            local cur_track = reaper.GetTrack(0, i)
            local cur_depth = reaper.GetTrackDepth(cur_track)
            if cur_depth <= depth then break end -- Break if no parent track in current folder
            if reaper.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH") == 1 then
                index = i
                break
            end
        end
        local child = reaper.GetTrack(0, index)
        undo_text = "Move selection down to first child of last folder."
        reaper.SetOnlyTrackSelected(child)
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(undo_text, -1)
reaper.UpdateArrange()
