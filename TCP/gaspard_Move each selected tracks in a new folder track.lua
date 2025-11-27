--@description Move each selected tracks in a new folder track
--@author gaspard
--@version 1.0.1
--@changelog Select only folder tracks
--@about Move each selected tracks in a new folder track

local track_count = reaper.CountSelectedTracks(0)
if track_count < 1 then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local folders = {}

-- Add new folder tracks and move selected tracks inside
for i = 1, track_count do
    local track = reaper.GetSelectedTrack(0, i - 1)
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    reaper.InsertTrackInProject(0, track_idx - 1, 0)
    local folder = reaper.GetTrack(0, track_idx - 1)
    folders[#folders + 1] = folder

    reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", -1)

    reaper.SetMediaTrackInfo_Value(folder, "I_FOLDERDEPTH", 1)
end

reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks

-- Select all folder tracks
for i, folder in ipairs(folders) do
    reaper.SetTrackSelected(folder, true)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Moved each selected tracks in a new folder track", -1)
