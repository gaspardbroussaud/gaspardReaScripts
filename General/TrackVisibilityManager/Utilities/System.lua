-- @noindex
-- @description Track Visibility Manager functions
-- @author gaspard
-- @about All functions used in gaspard_Track Visibility Manager.lua script

-- SET GLOBAL VARIABLES
function System_SetVariables()
    selected_tracks = {}
    track_count = 0
    selected_track_count = 0
    tracks = {}
end

-- GET SELECTED TRACKS TO RE-SELECT AFTER SCRIPT END
function System_GetSelectedTracksTable()
    selected_tracks = {}
    selected_track_count = reaper.CountSelectedTracks(0)

    if selected_track_count ~= 0 then
        for i = 0, selected_track_count - 1 do
            selected_tracks[i] = reaper.GetSelectedTrack(0, i)
        end
    end
end

-- SET SELECTED TRACKS BACK TO THEIR SELECTION STATE IF VISIBLE
function System_SetSelectedTracksBack()
    if selected_track_count ~= 0 then
        for i = 0, #selected_tracks do
            if reaper.GetMediaTrackInfo_Value(selected_tracks[i], "B_SHOWINTCP") ~= 10 then
                reaper.SetTrackSelected(selected_tracks[i], true)
            end
        end
    end
end

---comment
---@param track any
---@return any track
---@return integer depth
-- GET TOP PARENT TRACK
function System_GetTopParentTrack(track)
    local depth = 0
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
            depth = depth + 1
        else
            return track, depth
        end
    end
end

---comment
---@param track any
-- RETURN TRUE IF A PARENT IS MUTE
function System_IsParentMute(track)
    while true do
        if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
            return true
        end

        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
        else
            return false
        end
    end
end

---comment
---@param track any
-- RETURN TRUE IF A PARENT IS SOLO
function System_IsParentSolo(track)
    while true do
        if reaper.GetMediaTrackInfo_Value(track, "I_SOLO") > 0 then
            return track, true
        end

        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
        else
            return track, false
        end
    end
end

---comment
---@param index integer
-- SET ALL PARENT SOLO OF TRACK TO -1
function System_IsOneSubParentsSolo(index)
    for i = index + 1, #tracks do
        if tracks[i].depth <= tracks[index].depth then return false end
        if tracks[i].mute == 0 and tracks[i].solo == 1 then return true end
    end
    return false
end

function System_IsOtherChildSoloed(index)
    if tracks[index].solo < 1 then
        for i = index, #tracks do
            if tracks[i].depth < tracks[index].depth then return false end
            if tracks[i].solo == 1 then return true end
        end
    end
end

function System_FindTrackInTracksTab(track)
    for i = 0, #tracks do
        if tracks[i].id == track then return i end
    end
    return nil
end

---comment
---@param track any
-- GET TOP PARENT TRACK
function System_IsParentCollapsed(track)
    while true do
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") > 1 then
            return true
        end

        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
        else
            return false
        end
    end
end

-- GET PARENT TRACK MATCH FOR TRACK VISIBILITY
function System_GetParentTrackMatch(track, target)
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            if parent ~= target then
                track = parent
            else
                return true
            end
        else
            return false
        end
    end
end

-- GET ALL TRACKS FROM PROJECT
function System_GetTracksTable()
    track_count = reaper.CountTracks(0)

    -- Get all tracks and extract datas
    tracks = {}
    local inner_depth = 0.0
    for i = 0, track_count - 1 do
        -- Track reaper data 
        local t_id = reaper.GetTrack(0, i)

        -- Track number top to bottom
        local t_number = tostring(reaper.GetMediaTrackInfo_Value(t_id, "IP_TRACKNUMBER")):sub(1, -3)

        -- Track visibility in TCP state (shown or hidden)
        local t_state = reaper.GetMediaTrackInfo_Value(t_id, "B_SHOWINTCP")

        -- Track selection state in TCP
        local t_select = false
        if link_tcp_select then t_select = reaper.IsTrackSelected(t_id) end

        -- Track folder depth with parent folders
        local t_depth = reaper.GetTrackDepth(t_id)

        -- Track collapsed state for folders (-1 if not a folder track)
        local t_collapse = -1
        if reaper.GetMediaTrackInfo_Value(t_id, "I_FOLDERDEPTH") == 1 then
            if link_tcp_collapse then t_collapse = reaper.GetMediaTrackInfo_Value(t_id, "I_FOLDERCOMPACT")
            else t_collapse = 0 end
        end

        -- Track mute state if link tcp mute setting enabled
        local t_mute = 0
        if link_tcp_mute then t_mute = reaper.GetMediaTrackInfo_Value(t_id, "B_MUTE") end

        local t_solo = reaper.GetMediaTrackInfo_Value(t_id, "I_SOLO")

        -- Track visibility in GUI
        local t_visible = true

        tracks[i] = { id = t_id, number = t_number, state = t_state, select = t_select, depth = t_depth, collapse = t_collapse, mute = t_mute, solo = t_solo, visible = t_visible }
    end

    if track_count ~= 0 and link_tcp_collapse then
        for i = 0, #tracks do
            if tracks[i].collapse ~= -1 then
                System_UpdateTrackCollapse(i, tracks[i].collapse)
            end
        end
    end
end

-- GET TRACK MUTE
function System_GetTrackMuteIndex(track)
    for i = 0, #tracks do
        if tracks[i].id == track then
            return i
        end
    end
    return nil
end

-- HIDE TRACK WHEN UNSELECTING CHECKBOX
function System_HideTrack(track)
    reaper.SetTrackSelected(track, true)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0) -- Select all children
        reaper.SetTrackSelected(track, true)
    end

    for m = 0, reaper.CountSelectedTracks(0) - 1 do
        local cur_track = reaper.GetSelectedTrack(0, m)
        if reaper.GetMediaTrackInfo_Value(cur_track, "B_MUTE") == 1 then
            reaper.SetMediaTrackInfo_Value(cur_track, "I_HEIGHTOVERRIDE", 1)
            reaper.SetMediaTrackInfo_Value(cur_track, "B_HEIGHTLOCK", 1)
        else
            reaper.SetMediaTrackInfo_Value(cur_track, "B_MUTE", 1)
        end

        reaper.SetMediaTrackInfo_Value(cur_track, "I_SOLO", 0)
    end

    reaper.Main_OnCommand(41312, 0) -- Lock selected track

    for m = 0, reaper.CountSelectedTracks(0) - 1 do
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_SHOWINTCP", 0)
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_SHOWINMIXER", 0)
    end

    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
end

-- SHOW TRACK WHEN SELECTING CHECKBOX
function System_ShowTrack(track)
    reaper.SetTrackSelected(track, true)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0) -- Select all children
        reaper.SetTrackSelected(track, true)
    end

    for m = 0, reaper.CountSelectedTracks(0) - 1 do
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_SHOWINTCP", 1)
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_SHOWINMIXER", 1)
    end

    reaper.Main_OnCommand(41313, 0) -- Unlock selected track

    for m = 0, reaper.CountSelectedTracks(0) - 1 do
        local cur_track = reaper.GetSelectedTrack(0, m)
        local mute = 0
        local height = reaper.GetMediaTrackInfo_Value(cur_track, "I_HEIGHTOVERRIDE")
        local locked_height = reaper.GetMediaTrackInfo_Value(cur_track, "B_HEIGHTLOCK")
        if locked_height and height == 1 then
            mute = 1
            reaper.SetMediaTrackInfo_Value(cur_track, "I_HEIGHTOVERRIDE", 0)
            reaper.SetMediaTrackInfo_Value(cur_track, "B_HEIGHTLOCK", 0)
        end

        reaper.SetMediaTrackInfo_Value(cur_track, "B_MUTE", mute)
    end

    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
end

-- TOGGLE BUTTON STATE IN REAPER
function System_SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- SET TRACK TO FALSE OR TRUE WITH INDEX
function System_SetTrackVisibility(index, visibility)
    tracks[index].select = visibility
    if link_tcp_select then
        reaper.SetTrackSelected(tracks[index].id, visibility)
    end
end

-- UPDATE TRACK COLLAPSE IF ENABLED
function System_UpdateTrackCollapse(index, new_collapse)
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    local parent_visible = true
    local parent_depth = 0

    -- Update collapse state for parent track
    if not new_collapse then
        if tracks[index].collapse > 1 then
            tracks[index].collapse = 0
            parent_visible = true
        else
            parent_visible = false
            tracks[index].collapse = 2
        end
    else
        tracks[index].collapse = new_collapse
        if new_collapse > 1 then
            parent_visible = false
        else
            parent_visible = true
            if System_IsParentCollapsed(tracks[index].id) then
                parent_visible = false
            end
        end
    end

    -- Apply collapse state of parent to children
    for i = index + 1, #tracks do
        if System_GetParentTrackMatch(tracks[i].id, tracks[index].id) then
            if tracks[index].collapse > 1 then
                tracks[i].visible = false
            else
                if reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERDEPTH") == 1 then
                    if tracks[i].depth <= parent_depth then
                        parent_visible = true
                        parent_depth = tracks[i].depth
                    end
                    if parent_visible then
                        tracks[i].visible = true
                        if tracks[i].collapse > 1 then
                            parent_visible = false
                            parent_depth = tracks[i].depth
                        end
                    else
                        tracks[i].visible = false
                    end
                else
                    if tracks[i].depth <= parent_depth then
                        parent_visible = true
                        parent_depth = tracks[i].depth
                    end
                    tracks[i].visible = parent_visible
                end
            end
        else
            return
        end
    end

    reaper.Undo_EndBlock("Tracks collapsed or uncollapsed via Track Visibility Tool.", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- UPDATE THE SOLO STATE COMPARED TO SOLO AND MUTE ON TRACKS
function System_UpdateSoloState()
    for i = 0, #tracks do
        if tracks[i].solo > 0 then return true end
    end
    return false
end

-- WRITE SETTINGS IN FILE
function System_WriteSettingsFile()
    local file = io.open(settings_path, "w")
    if file then
        file:write(tostring(link_tcp_select).."\n"..tostring(link_tcp_collapse).."\n"..tostring(link_tcp_mute).."\n"..tostring(show_mute_buttons).."\n"..tostring(link_tcp_solo).."\n"..tostring(show_solo_buttons))
        file:close()
    end
end

-- READ SETTINGS IN FILE AT LAUNCH
function System_ReadSettingsFile()
    link_tcp_select = false
    link_tcp_collapse = false
    link_tcp_mute = false
    show_mute_buttons = false
    link_tcp_solo = false
    show_solo_buttons = false

    local file = io.open(settings_path, "r")
    if file then
        link_tcp_select = System_StringToBool(file:read("l"))
        link_tcp_collapse = System_StringToBool(file:read("l"))
        link_tcp_mute = System_StringToBool(file:read("l"))
        show_mute_buttons = System_StringToBool(file:read("l"))
        link_tcp_solo = System_StringToBool(file:read("l"))
        show_solo_buttons = System_StringToBool(file:read("l"))
        file:close()
    end

    System_WriteSettingsFile()
end

function System_StringToBool(str)
    if str then
        str = string.lower(str)
        if str == "true" then
            return true
        elseif str == "false" then
            return false
        else
            return false
        end
    end
end
