--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local _TRACKS = {}

_TRACKS.COUNT = reaper.CountSelectedTracks(-1)

return _TRACKS
