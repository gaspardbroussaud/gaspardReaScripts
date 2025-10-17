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
        MARKERS.DeleteMarkers(SYS.TRACKS.PARENT)
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
    track = SYS.TRACKS.PARENT
    local edit_cursor_pos = reaper.GetPlayState() == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()

    local parent_guid = reaper.GetTrackGUID(track)

    local marker_name = select(2, reaper.GetTrackName(track)) .. "_" .. parent_guid

    edit_cursor_pos = tonumber(tostring(edit_cursor_pos))

    local index = reaper.AddProjectMarker(0, false, edit_cursor_pos, edit_cursor_pos, marker_name, -1) - 1

    --[[for i = 1, reaper.CountProjectMarkers(0) do
        local retenum, isrgn, pos, _, name = reaper.EnumProjectMarkers(i - 1)
        if retenum and not isrgn and pos == edit_cursor_pos and name == marker_name then
            index = i - 1
            break
        end
    end

    --local _, marker_GUID = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:" .. index, "", false)

    --[[local retmarker, markers_text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)
    if retmarker then
        local list = MARKERS.SplitMarkerPos(markers_text)
        local pos = tonumber(tostring(edit_cursor_pos))
        table.insert(list, pos)
        table.sort(list, function(a, b) return a < b end)
        local text = MARKERS.ConcatMarkerPos(list)

        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", text, true)
    else
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", tostring(edit_cursor_pos), true)
    end]]

    --return marker_GUID -- Return last marker GUID (aka newly created)
end

MARKERS.InsertMarkers = function(track)
    if not track then return end

    -- Get from track ext state
    local retval, text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)
    if not retval then return end

    local pos_list = MARKERS.SplitMarkerPos(text)
    if #pos_list < 1 then return end

    local name = select(2, reaper.GetTrackName(track)) .. "_" .. reaper.GetTrackGUID(track)

    for i, pos in ipairs(pos_list) do
        reaper.AddProjectMarker(0, false, pos, pos, name, 0)
    end

    -- Remove from track ext state
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", true)
end

local function SaveMarkerPos(track)
    local markers_text = MARKERS.ConcatMarkerPos(MARKERS.LIST)

    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", markers_text, true)
end

MARKERS.DeleteMarkers = function(track)
    if not track then return end

    local pos_list = {}
    for i, marker in ipairs(MARKERS.LIST) do
        pos_list[i] = marker.pos
    end
    if #pos_list < 1 then return end

    -- Save markers in track ext state
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", MARKERS.ConcatMarkerPos(pos_list), true)
    local _, text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)

    -- Delete markers from project
    for i, marker in ipairs(MARKERS.LIST) do
        local _, index = reaper.GetSetProjectInfo_String(0, "MARKER_INDEX_FROM_GUID:"..marker.guid, "", false)
        reaper.DeleteProjectMarkerByIndex(0, index)
    end
end

return MARKERS
