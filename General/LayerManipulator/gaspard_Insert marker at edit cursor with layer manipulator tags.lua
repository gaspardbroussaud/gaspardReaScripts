--@description Insert marker at edit cursor with layer manipulator tags
--@author gaspard
--@version 0.0.1b
--@changelog Init
--@about Insert marker at edit cursor with layer manipulator tags

local selected_count = reaper.CountSelectedTracks(-1)
if selected_count > 0 then
    local edit_cursor_pos = reaper.GetPlayStateEx(-1) == 2 and reaper.GetCursorPosition() or reaper.GetPlayPosition()

    local parent_track = nil
    local parent_guid = nil
    for i = 1, selected_count do
        local cur_track = reaper.GetSelectedTrack(-1, i-1)
        local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(cur_track, "P_EXT:g_LM_PARENT_GUID", "", false)
        if retval then
            parent_track = reaper.BR_GetMediaTrackByGUID(-1, parent_GUID)
            parent_guid = parent_GUID
            break
        end
    end

    if not parent_track then reaper.MB("Please select a track in tracks group.", "WARNING", 0) return end

    local name = select(2, reaper.GetTrackName(parent_track)).."_"..parent_guid
    reaper.AddProjectMarker(-1, false, edit_cursor_pos, edit_cursor_pos, name, -1)
else
    reaper.MB("Please select a track in tracks group.", "WARNING", 0)
end
