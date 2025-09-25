--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local MARKERS = {}

MARKERS.COUNT = select(2, reaper.CountProjectMarkers(-1)) or 0

MARKERS.LIST = {}

MARKERS.GetGroupMarkers = function()
    if not SYS.TRACKS.PARENT then
        MARKERS.LIST = {}
        MARKERS.COUNT = 0
        return
    end
    MARKERS.LIST = {}
    local _, marker_count, rgn_count = reaper.CountProjectMarkers(-1)
    MARKERS.COUNT = marker_count
    if MARKERS.COUNT > 0 then
        for i = 1, MARKERS.COUNT + rgn_count do
            local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(-1, i-1)
            if retval and not isrgn then
                if name:match("{[%x%-]+}$") == reaper.GetTrackGUID(SYS.TRACKS.PARENT) then
                    local _, marker_guid = reaper.GetSetProjectInfo_String(-1, "MARKER_GUID:"..tostring(i-1), "", false)
                    table.insert(MARKERS.LIST, {guid = marker_guid, pos = pos, name = name, index = markrgnindexnumber})
                end
            end
        end
    end
end

return MARKERS
