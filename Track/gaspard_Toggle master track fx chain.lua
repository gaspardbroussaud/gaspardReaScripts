--@description Toggle master track fx chain
--@author gaspard
--@version 1.0.0
--@changelog Init
--@about Toggle master track fx chain.

local master = reaper.GetMasterTrack(0)

if reaper.GetMediaTrackInfo_Value(master, "I_FXEN") == 1 then
  reaper.SetMediaTrackInfo_Value(master, "I_FXEN", 0)
else
  reaper.SetMediaTrackInfo_Value(master, "I_FXEN", 1)
end
