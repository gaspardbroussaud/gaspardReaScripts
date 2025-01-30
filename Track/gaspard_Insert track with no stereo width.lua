--@description Insert track with no stereo width
--@author gaspard
--@version 1.0
--@changelog
--  - Add script
--@about
--  ###Insert track with no stereo width

local track_count = reaper.CountTracks(0)
reaper.InsertTrackInProject(0, track_count, 0)
local track = reaper.GetTrack(0, track_count)
reaper.SetMediaTrackInfo_Value(track, 'D_WIDTH', 0)
