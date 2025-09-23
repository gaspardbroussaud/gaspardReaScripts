--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local MARKERS = {}

MARKERS.COUNT = select(2, reaper.CountProjectMarkers(-1))

MARKERS.marker_list = {}

return MARKERS
