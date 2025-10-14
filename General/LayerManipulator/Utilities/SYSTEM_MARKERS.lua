--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local MARKERS = {}

MARKERS.COUNT = select(2, reaper.CountProjectMarkers(0)) or 0

MARKERS.LIST = {}

MARKERS.SplitMarkerPos = function(text)
    local list = {}

    for pos in text:gmatch("([^/]+)") do
        local num = tonumber(pos)
        if num then
            table.insert(list, num)
        end
    end

    return list
end

MARKERS.ConcatMarkerPos = function(list)
    local str_list = {}
    for i, v in ipairs(list or {}) do
        str_list[#str_list + 1] = tostring(v)
    end
    return table.concat(str_list, "/")
end

MARKERS.GetGroupMarkers = function()
    if not SYS.TRACKS.PARENT then
        MARKERS.LIST = {}
        MARKERS.COUNT = 0
        return
    end
    MARKERS.LIST = {}
    local _, marker_count, rgn_count = reaper.CountProjectMarkers(0)
    MARKERS.COUNT = 0
    if marker_count > 0 then
        for i = 1, marker_count + rgn_count do
            local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(0, i - 1)
            if retval and not isrgn then
                if name:match("{[%x%-]+}$") == reaper.GetTrackGUID(SYS.TRACKS.PARENT) then
                    local _, marker_guid = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:" .. tostring(i - 1), "", false)
                    table.insert(MARKERS.LIST, {guid = marker_guid, pos = pos, name = name, index = markrgnindexnumber})
                    MARKERS.COUNT = MARKERS.COUNT + 1
                end
            end
        end
    end
end

MARKERS.AddMarkerToTrack = function(track)
    local edit_cursor_pos = reaper.GetPlayState() == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()

    local marker_name = select(2, reaper.GetTrackName(SYS.TRACKS.PARENT))--.."_"..parent_guid

    local index = reaper.AddProjectMarker(0, false, edit_cursor_pos, edit_cursor_pos, marker_name, -1) - 1

    for i = 1, reaper.CountProjectMarkers(0) do
        local retenum, isrgn, pos, _, name = reaper.EnumProjectMarkers(i - 1)
        if retenum and not isrgn and pos == edit_cursor_pos and name == marker_name then
            index = i - 1
            break
        end
    end

    local _, marker_GUID = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:" .. index, "", false)

    local retmarker, markers_text = reaper.GetSetMediaTrackInfo_String(SYS.TRACKS.PARENT, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)
    if retmarker then
        local list = MARKERS.SplitMarkerPos(markers_text)
        table.insert(list, edit_cursor_pos)
        table.sort(list, function(a, b) return a < b end)
        local text = MARKERS.ConcatMarkerPos(list)

        reaper.GetSetMediaTrackInfo_String(SYS.TRACKS.PARENT, "P_EXT:" .. SYS.extname .. "MARKERS", text, true)
    else
        reaper.GetSetMediaTrackInfo_String(SYS.TRACKS.PARENT, "P_EXT:" .. SYS.extname .. "MARKERS", tostring(edit_cursor_pos), true)
    end

    return marker_GUID -- Return last marker GUID (aka newly created)

    --[[local _, index = reaper.GetSetProjectInfo_String(0, "MARKER_INDEX_FROM_GUID:"..tostring(GUID), "", false)
    reaper.SetProjectMarker(index, false, pos, rgnend, name)]]
end

MARKERS.ShowMarkers = function(group)
    for i, marker in ipairs(group.markers) do
        reaper.ShowConsoleMsg(marker.pos)
    end
end

MARKERS.DeleteMarkers = function(track)
    local retmarker, markers_text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)
    if not retmarker then return end

    local marker_list = MARKERS.SplitMarkerPos(markers_text)
    for i, guid in ipairs(marker_list) do
        local retval, index = false, 0
        reaper.GetSetProjectInfo_String(0, "MARKER_INDEX_FROM_GUID:"..tostring(guid), "", true)
        if retval then
            reaper.DeleteProjectMarker(0, index, false)
        end
    end
end

return MARKERS
