--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local _MARKERS = {}

_MARKERS.COUNT = select(2, reaper.CountProjectMarkers(-1))

return _MARKERS
