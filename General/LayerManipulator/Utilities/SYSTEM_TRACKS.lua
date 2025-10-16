--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local TRACKS = {}

TRACKS.COUNT = -1--reaper.CountSelectedTracks(0)
TRACKS.GROUPS = {}
TRACKS.PARENT = nil

local function GetParent(track_test)
    local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track_test, "P_EXT:"..SYS.extname.."PARENT_GUID", "", false)
    if not retval then return nil end

    return reaper.BR_GetMediaTrackByGUID(0, parent_GUID)
end

local function SplitFilesPath(text)
    local list = {}

    for filepath in text:gmatch("([^*]+)") do
        local filename = filepath:match('([^\\/]+)$')
        local name_without_extension = filename:match("(.+)%..+") or filename
        table.insert(list, {name = name_without_extension, path = filepath})
    end

    return list
end

TRACKS.GetTrackGroups = function(selected_track)
    local parent_track = GetParent(selected_track)
    if not parent_track then
        TRACKS.PARENT = nil
        return nil
    end
    --if parent_track == TRACKS.PARENT then return TRACKS.GROUPS
    --else TRACKS.PARENT = parent_track end
    if parent_track ~= TRACKS.PARENT then TRACKS.PARENT = parent_track end

    local parent_index = reaper.GetMediaTrackInfo_Value(TRACKS.PARENT, "IP_TRACKNUMBER")

    local list = {}
    for i = parent_index, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "PARENT_GUID", "", false)
        if not retval or reaper.BR_GetMediaTrackByGUID(0, parent_GUID) ~= TRACKS.PARENT then break end

        table.insert(list, track)
    end

    local groups = {}
    if #list > 0 then
        for i, track in ipairs(list) do
            local GUID = reaper.GetTrackGUID(track)
            local _, name = reaper.GetTrackName(track)
            local parent = reaper.GetParentTrack(track)
            local retsel, selected = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "SELECTED", "", false)
            if not retsel then
                selected = false
                reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "SELECTED", tostring(selected), true)
            else
                selected = selected == "true" and true or false
            end

            local file_list = {}
            local retfiles, files_text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "FILES", "", false)
            if retfiles then file_list = SplitFilesPath(files_text) end

            local marker_list = {}
            local retmarker, markers_text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "MARKERS", "", false)
            if retmarker then marker_list = SYS.MARKERS.SplitMarkerPos(markers_text) end

            groups[i] = {track = track, guid = GUID, name = name, parent = parent, selected = selected, files = file_list, markers = marker_list}
        end
    end

    return #groups > 0 and groups or nil
end

TRACKS.InsertFileInGroup = function(track, path)
    local text = ""

    local retfiles, files_text = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "FILES", "", false)

    if retfiles then
        text = files_text .. "**" .. path
    else
        text = path
    end

    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "FILES", text, true)
end

TRACKS.GetRandomFileFromGroup = function(group)
    if group.files and #group.files > 0 then
        local random = math.floor(math.random(1, #group.files))
        return group.files[random]
    else
        return nil
    end
end

TRACKS.MakeGroupParentTrack = function(parent_track)
    local parent_depth = reaper.GetTrackDepth(parent_track)
    local parent_index = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER")
    local parent_GUID = reaper.GetTrackGUID(parent_track)

    reaper.GetSetMediaTrackInfo_String(parent_track, "P_EXT:" .. SYS.extname .. "PARENT_GUID", parent_GUID, true)

    for i = parent_index, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        if reaper.GetTrackDepth(track) <= parent_depth then break end

        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. SYS.extname .. "PARENT_GUID", parent_GUID, true)
    end
end

TRACKS.RemoveFileFromGroup = function(group, index)
    table.remove(group.files, index)

    local text = ""

    for i, file in ipairs(group.files) do
        text = text .. "**" .. file.path
    end

    text = text:gsub("^**", "")

    reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "FILES", text, true)
end

return TRACKS
