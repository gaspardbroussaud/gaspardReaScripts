--@description Play from start of time selection
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Play from start of time selection.

local loop_start, loop_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
reaper.SetEditCurPos2(0, loop_start, true, true)
reaper.Main_OnCommand(40044, 0)
