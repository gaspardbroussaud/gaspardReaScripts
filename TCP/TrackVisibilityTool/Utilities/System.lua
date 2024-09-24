-- @noindex
function System_SetVariables()
    selected_tracks = {}
    track_count = 0
    selected_track_count = 0
    tracks = {}
end

-- GET SELECTED TRACKS TO RE-SELECT AFTER SCRIPT END --
function System_GetSelectedTracksTable()
    selected_tracks = {}
    selected_track_count = reaper.CountSelectedTracks(0)

    if selected_track_count ~= 0 then
        for i = 0, selected_track_count - 1 do
            selected_tracks[i] = reaper.GetSelectedTrack(0, i)
        end
    end
end

-- GET TOP PARENT TRACK --
function System_GetTopParentTrack(track)
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
        else
            return track
        end
    end
end

-- GET ALL TRACKS FROM PROJECT --
function System_GetTracksTable()
    track_count = reaper.CountTracks(0)

    -- Get all tracks and extract datas --
    tracks = {}
    local parent_check = false
    local inner_depth = 0.0
    for i = 0, track_count - 1 do
        local track_id = reaper.GetTrack(0, i)
        local track_state = reaper.GetMediaTrackInfo_Value(track_id, "B_SHOWINTCP")
        local track_select = reaper.IsTrackSelected(track_id)
        local track_depth = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERDEPTH")
        local track_collapse = -1
        if track_depth == 1 then
            track_collapse = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERCOMPACT")
        end
        
        --local track_top_parent = get_top_parent_track(track_id)

        if not reaper.GetParentTrack(track_id) then inner_depth = 0 end
        local cur_depth = inner_depth
        if track_depth > 0 then inner_depth = inner_depth + 1
        elseif track_depth < 0 then inner_depth = inner_depth - 1 end
        track_depth = cur_depth

        local track_visible = true

        tracks[i] = { id = track_id, state = track_state, select = track_select, depth = cur_depth, collapse = track_collapse, visible = track_visible }
    end
    if track_count ~= 0 then
        System_UpdateTrackCollapse()
    end
end

-- HIDE TRACK WHEN UNSELECTING CHECKBOX --
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

-- SHOW TRACK WHEN SELECTING CHECKBOX --
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

function System_SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- SET TRACK TO FALSE OR TRUE WITH INDEX --
function System_SetTrackVisibility(index, visibility)
    tracks[index].select = visibility
    if link_tcp_select then
        reaper.SetTrackSelected(tracks[index].id, visibility)
    end
end

-- CHECK FOR TRACK SELECTION CHANGE IN PROJECT --
function System_CheckTrackSelection()
    if link_tcp_select then
        if reaper.CountSelectedTracks(0) ~= 0 and selected_tracks then
            local update_tracks_selection = false
            for i = 0, reaper.CountSelectedTracks(0) - 1 do
                if selected_tracks[i] ~= reaper.GetSelectedTrack(0, i) then
                    update_tracks_selection = true
                end
            end
            if update_tracks_selection then
                System_GetSelectedTracksTable()
                System_GetTracksTable()
            end
        else
            if selected_tracks then
                if #selected_tracks ~= 0 then
                    for i = 0, #selected_tracks do
                        reaper.SetTrackSelected(selected_tracks[i], false)
                    end
                else
                    System_GetSelectedTracksTable()
                    System_GetTracksTable()
                end
            end
        end
    end
end

-- UPDATE TRACK COLLAPSE IF ENABLED --
function System_UpdateTrackCollapse()
    local parent_depth = 0
    for i = 0, #tracks do
        if tracks[i].collapse > 1 then
            if tracks[i].depth <= parent_depth then
                local out = false
                local first = tracks[i].depth
                for j = i + 1, #tracks do
                    if not out then
                        if tracks[j].depth == 0 or tracks[j].depth <= first then
                            out = true
                        else
                            tracks[j].visible = false
                        end
                    end
                end
                parent_depth = tracks[i].depth
            else
                --parent_depth = tracks[i].depth
            end
        end
        --[[if tracks[i].collapse ~= -1 then
            if tracks[i].collapse > 1 then
                if tracks[i].depth <= parent_depth then
                    if tracks[i].collapse > 1 then
                        local out = false
                        local first = tracks[i].depth
                        for j = i + 1, #tracks do
                            if not out then
                                if tracks[j].depth == 0 or tracks[j].depth <= first then
                                    out = true
                                else
                                    tracks[j].visible = false
                                end
                            end
                        end
                    end
                    parent_depth = tracks[i].depth
                end
            end
        else
            parent_depth = tracks[i].depth
        end]]
    end
end

--[[function System_QuitApp()
    System_SetButtonState()
    window_open = false
end]]
