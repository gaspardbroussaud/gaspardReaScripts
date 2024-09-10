-- @description Rename selected tracks to "Video"
-- @author gaspard
-- @version 1.0
-- @changelog Initial release.
-- @about Renames all selected tracks to "Video".

-- CHECK TRACK SELECTION --
sel_tracks = reaper.CountSelectedTracks(0)
if sel_tracks ~= 0 then
    for i = 0, sel_tracks - 1 do
        reaper.GetSetMediaTrackInfo_String(reaper.GetSelectedTrack(0, i), "P_NAME", "Video", true)
    end
end
