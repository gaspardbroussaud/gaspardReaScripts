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
        local track_id = reaper.GetTrack(0, i)

        -- Track number top to bottom
        local track_number = tostring(reaper.GetMediaTrackInfo_Value(track_id, "IP_TRACKNUMBER")):sub(1, -3)

        -- Track visibility in TCP state (shown or hidden)
        local track_state = reaper.GetMediaTrackInfo_Value(track_id, "B_SHOWINTCP")

        -- Track selection state in TCP
        local track_select = false
        if link_tcp_select then track_select = reaper.IsTrackSelected(track_id) end

        -- Track folder depth with parent folders
        local track_depth = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERDEPTH")

        -- Track collapsed state for folders (-1 if not a folder track)
        local track_collapse = -1
        if track_depth == 1 then
            track_collapse = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERCOMPACT")
        end

        -- Parent of track
        local track_parent = reaper.GetParentTrack(track_id)

        if not track_parent then inner_depth = 0
        else _, inner_depth = System_GetTopParentTrack(track_id) end
        local cur_depth = inner_depth
        if track_depth > 0 then inner_depth = inner_depth + 1
        elseif track_depth < 0 then inner_depth = inner_depth - 1 end
        track_depth = cur_depth

        -- Track visibility in GUI
        local track_visible = true

        tracks[i] = { id = track_id, number = track_number, state = track_state, select = track_select, depth = track_depth, collapse = track_collapse, visible = track_visible }
    end

    if track_count ~= 0 then
        for i = 0, #tracks do
            System_UpdateTrackCollapse(i, nil)
        end
    end
end

-- HIDE TRACK WHEN UNSELECTING CHECKBOX
function System_HideTrack(track)
    reaper.SetTrackSelected(track, true)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0) -- Select all children
        reaper.SetTrackSelected(track, true)
    end

    for m = 0, reaper.CountSelectedTracks(0) - 1 do
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_MUTE", 1)
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
        reaper.SetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, m), "B_MUTE", 0)
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

-- WRITE SETTINGS IN FILE
function System_WriteSettingsFile(setting_select, setting_colapse)
    local file = io.open(settings_path, "w")
    if file then
        file:write(tostring(setting_select).."\n"..tostring(setting_colapse))
        file:close()
    end
end

-- READ SETTINGS IN FILE AT LAUNCH
function System_ReadSettingsFile()
    local setting_select = false
    local setting_collapse = false
    local file = io.open(settings_path, "r")
    if file then
        setting_select = file:read("l")
        setting_collapse = file:read("l")
        file:close()
        if setting_select == "true" then setting_select = true
        else setting_select = false end
        if setting_collapse == "true" then setting_collapse = true
        else setting_collapse = false end
    else
        setting_select = false
        setting_collapse = false
        System_WriteSettingsFile(setting_select, setting_collapse)
    end
    link_tcp_select = setting_select
    link_tcp_collapse = setting_collapse
end
