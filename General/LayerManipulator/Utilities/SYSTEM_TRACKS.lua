--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local TRACKS = {}

TRACKS.COUNT = reaper.CountSelectedTracks(-1)
TRACKS.LIST = {}

TRACKS.GetTrackGroups = function()
    if TRACKS.COUNT > 0 then
        --for i = 0, 
    end
end

return TRACKS
