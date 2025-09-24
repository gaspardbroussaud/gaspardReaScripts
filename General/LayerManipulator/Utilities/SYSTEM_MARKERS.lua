--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local MARKERS = {}

MARKERS.COUNT = select(2, reaper.CountProjectMarkers(-1))

MARKERS.LIST = {1, 2, 3}

return MARKERS
