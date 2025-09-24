--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local TRACKS = {}

TRACKS.COUNT = -1--reaper.CountSelectedTracks(-1)
TRACKS.GROUPS = {}
TRACKS.PARENT = nil

local function GetParent(track_test)
    local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track_test, "P_EXT:"..SYS.extname.."PARENT_GUID", "", false)
    if not retval then return nil end

    return reaper.BR_GetMediaTrackByGUID(0, parent_GUID)
end

TRACKS.GetTrackGroups = function(selected_track)
    local parent_track = GetParent(selected_track)
    if not parent_track then
        TRACKS.PARENT = nil
        return nil
    end
    if parent_track == TRACKS.PARENT then return TRACKS.GROUPS
    else TRACKS.PARENT = parent_track end

    local parent_index = reaper.GetMediaTrackInfo_Value(TRACKS.PARENT, "IP_TRACKNUMBER")

    local list = {}
    for i = parent_index, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..SYS.extname.."PARENT_GUID", "", false)
        if not retval or reaper.BR_GetMediaTrackByGUID(0, parent_GUID) ~= TRACKS.PARENT then break end

        table.insert(list, track)

        --[[if reaper.BR_GetMediaTrackByGUID(0, parent_GUID) == TRACKS.PARENT then
            table.insert(list, track)
        else
            break
        end]]
    end

    local groups = {}
    if #list > 0 then
        for i, track in ipairs(list) do
            local GUID = reaper.GetTrackGUID(track)
            local _, name = reaper.GetTrackName(track)
            local parent = reaper.GetParentTrack(track)
            local retsel, selected = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..SYS.extname.."SELECTED", "", false)
            if not retsel then
                selected = false
                reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..SYS.extname.."SELECTED", tostring(selected), true)
            else
                selected = selected == "true" and true or false
            end

            groups[i] = {track = track, guid = GUID, name = name, parent = parent, selected = selected}
        end
    end

    return #groups > 0 and groups or nil
end

return TRACKS
