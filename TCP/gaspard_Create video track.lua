-- @description Create video track
-- @author gaspard
-- @version 1.0.0
-- @about Create video track
-- @changelog Init

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local last = reaper.CountTracks(0)
reaper.InsertTrackInProject(0, last, 0)
reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, last), "P_NAME", "-Video", true)

reaper.Undo_EndBlock("Inserted video track.", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
