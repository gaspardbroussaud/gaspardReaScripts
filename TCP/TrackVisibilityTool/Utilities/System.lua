-- @noindex

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
        local track_id = reaper.GetTrack(0, i)
        local track_number = tostring(reaper.GetMediaTrackInfo_Value(track_id, "IP_TRACKNUMBER")):sub(1, -3)
        local track_state = reaper.GetMediaTrackInfo_Value(track_id, "B_SHOWINTCP")
        local track_select = reaper.IsTrackSelected(track_id)
        local track_depth = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERDEPTH")
        local track_collapse = -1
        if track_depth == 1 then
            track_collapse = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERCOMPACT")
        end
        
        local track_parent = reaper.GetParentTrack(track_id)

        if not track_parent then inner_depth = 0
        else _, inner_depth = System_GetTopParentTrack(track_id) end
        local cur_depth = inner_depth
        if track_depth > 0 then inner_depth = inner_depth + 1
        elseif track_depth < 0 then inner_depth = inner_depth - 1 end
        track_depth = cur_depth

        local track_visible = true

        tracks[i] = { id = track_id, number = track_number, state = track_state, select = track_select, depth = track_depth, collapse = track_collapse, visible = track_visible }
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

-- UPDATE TRACK SELECTION IF ENABLED
function System_UpdateTrackSelection()
    for i = 0, #tracks do
        tracks[i].select = reaper.IsTrackSelected(tracks[i].id)
    end
end

-- UPDATE TRACK COLLAPSE IF ENABLED
function System_UpdateTrackCollapse(index)
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    if tracks[index].collapse > 1 then
        tracks[index].collapse = 0
    else
        tracks[index].collapse = 2
    end

    for i = index + 1, #tracks do
        if System_GetParentTrackMatch(tracks[i].id, tracks[index].id) then
            if tracks[index].collapse > 1 then
                tracks[i].visible = false
            else
                tracks[i].visible = true
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
