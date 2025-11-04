--@description Uncollapse selected folder tracks
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Uncollapse selected folder tracks.

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for i = 1, track_count do
    local track = reaper.GetSelectedTrack(0, i - 1)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", 0)
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Uncollapsed all selected tracks.", -1)
reaper.UpdateArrange()
