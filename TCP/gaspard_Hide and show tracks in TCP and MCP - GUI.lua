-- @description Hide and show tracks in TCP and MCP - GUI
-- @author gaspard
-- @version 1.0.1
-- @changelog Prevent crash on no tracks in project.
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- SET ALL GLOBAL VARIABLES --
function set_variables()
    last_selected = -1
end

-- SET TRACK TO FALSE OR TRUE WITH INDEX --
function set_track_visibility(index, visibility)
    track_select[index] = visibility
    reaper.SetTrackSelected(tracks_tab[index], visibility)
end

-- GET SELECTED TRACKS TO RE-SELECT AFTER SCRIPT END --
function get_selected_tracks()
    if reaper.CountSelectedTracks(0) ~= 0 then
        selected_tracks = {}
        for i = 0, reaper.CountSelectedTracks(0) - 1 do
            selected_tracks[i] = reaper.GetSelectedTrack(0, i)
        end
        for i = 0, #selected_tracks do
            reaper.SetTrackSelected(selected_tracks[i], false)
        end
        are_tracks_selected = true
    else
        are_tracks_selected = false
    end
end

-- SELECT TRACKS IF SELECTED BEFORE RUNNING SCRIPT --
function set_selected_tracks()
    for i = 0, reaper.CountTracks(0) - 1 do
        reaper.SetTrackSelected(tracks_tab[i], false)
    end
    
    if are_tracks_selected then
        for i = 0, #selected_tracks do
            -- Prevents crash on selected track before running script being deleted --
            found = false
            for j = 0, reaper.CountTracks(0) - 1 do
                if selected_tracks[i] == reaper.GetTrack(0, j) then
                    found = true
                end
            end
            
            -- Re-select track if shown --
            if found then
                if reaper.GetMediaTrackInfo_Value(selected_tracks[i], "B_SHOWINTCP") == 1 then 
                    reaper.SetTrackSelected(selected_tracks[i], true)
                end
            end
        end
    end
end

-- GET ALL TRACKS FROM PROJECT --
function get_tracks_tab()
    tracks_tab = {}
    checkbox_state = {}
    track_select = {}
    track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        tracks_tab[i] = reaper.GetTrack(0, i)
        checkbox_state[i] = reaper.GetMediaTrackInfo_Value(tracks_tab[i], "B_SHOWINTCP")
        track_select[i] = false
    end
end

-- DETECT IF CURRENT TRACK IS A PARENT --
function detect_parent_state(track)

end

-- HIDE TRACK WHEN UNSELECTING CHECKBOX --
function hide_track(track)
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
function show_track(track)
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

-- GUI INIT --
function gui_init()
    ctx = reaper.ImGui_CreateContext('context_imgui')
    FONT = reaper.ImGui_CreateFont('sans-serif', 15)
    reaper.ImGui_Attach(ctx, FONT)
end

-- GUI ELEMENTS --
function gui_elements()
    flags = reaper.ImGui_TableFlags_SizingFixedFit() | reaper.ImGui_TableFlags_Borders()
    if reaper.ImGui_BeginTable(ctx, "table_tracks", 3, flags) then
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "ID")
        
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "STATE")
        
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "TRACK NAME")
        
        for i = 0, #tracks_tab do
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            track_number = tostring(reaper.GetMediaTrackInfo_Value(tracks_tab[i], "IP_TRACKNUMBER")):sub(1, -3)
            x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            text_x, _ = reaper.ImGui_CalcTextSize(ctx, track_number)
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
            selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap()
            x, y = reaper.ImGui_GetContentRegionAvail(ctx)
            changed, track_select[i] = reaper.ImGui_Selectable(ctx, track_number, track_select[i], selectable_flags, 0, 21)
            if changed then
                -- Get key press CTRL = 4096 or CMD = 32768 / SHIFT = 8192 --
                key_code = reaper.ImGui_GetKeyMods(ctx)
                ctrl, shift = false, false
                if key_code == 4096 or key_code == 32768 then ctrl = true
                elseif key_code == 8192 then shift = true end
                
                -- Multi selection system --
                if not ctrl and not shift then
                    if not track_select[i] then
                        for j = 0, #track_select do
                            if track_select[j] then
                                set_track_visibility(i, true)
                            end
                        end
                    end
                    
                    for j = 0, #track_select do
                        if track_select[i] == track_select[j] and i ~= j then
                            set_track_visibility(j, false)
                        end
                    end
                end
                
                if not ctrl and shift then
                    for j = 0, #track_select do
                        if last_selected < j and j < i then
                            set_track_visibility(j, true)
                        end
                        if last_selected > j and j > i then
                            set_track_visibility(j, true)
                        end
                    end
                end
                
                -- Set track visibility --
                if track_select[i] then
                    reaper.SetTrackSelected(tracks_tab[i], true)
                else
                    reaper.SetTrackSelected(tracks_tab[i], false)
                end
                
                last_selected = i
            end
            
            reaper.ImGui_TableNextColumn(ctx)
            x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - 21) * 0.5))
            changed, checkbox_state[i] = reaper.ImGui_Checkbox(ctx, "##checkbox"..tostring(i), checkbox_state[i])
            if changed then
                reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

                if track_select[i] then
                    for j = 0, #track_select do
                        if track_select[j] then
                            if checkbox_state[i] then
                                show_track(tracks_tab[j])
                            else
                                hide_track(tracks_tab[j])
                            end
                        end
                    end
                else
                    if checkbox_state[i] then
                        show_track(tracks_tab[i])
                    else
                        hide_track(tracks_tab[i])
                    end
                end

                for j = 0, #checkbox_state do
                    checkbox_state[j] = reaper.GetMediaTrackInfo_Value(tracks_tab[j], "B_SHOWINTCP")
                end

                for j = 0, #track_select do
                    if track_select[j] then
                        reaper.SetTrackSelected(tracks_tab[j], true)
                    end
                end
            end
            
            reaper.ImGui_TableNextColumn(ctx)
            _, text_cell = reaper.GetSetMediaTrackInfo_String(tracks_tab[i], "P_NAME", "", false)
            
            if text_cell == "" then text_cell = "Track "..track_number end
            
            space = " "
            parent = reaper.GetParentTrack(tracks_tab[i])
            if parent then parent_id = reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER") end
            
            text_cell = space..text_cell
            reaper.ImGui_Text(ctx, tostring(text_cell))
        end
        reaper.ImGui_EndTable(ctx)
    end
end

-- GUI LOOP --
function gui_loop()

    local window_flags = reaper.ImGui_WindowFlags_NoCollapse()
    -- Set the size of the windows. [[reaper.ImGui_Cond_FirstUseEver()]] --
    reaper.ImGui_SetNextWindowSize(ctx, 500, 300, reaper.ImGui_Cond_Once())
    reaper.ImGui_PushFont(ctx, FONT)

    local visible, open  = reaper.ImGui_Begin(ctx, 'TRACKS VISIBILITY STATE', true, window_flags)

    if visible then
        -- If track count updates (delete or add track) --
        if track_count ~= reaper.CountTracks(0) then
            get_tracks_tab()
        end
        gui_elements()
        reaper.ImGui_End(ctx)
    end 

    reaper.ImGui_PopFont(ctx)

    if open then
        reaper.defer(gui_loop)
    else
        set_selected_tracks()
    end
end

-- MAIN SCRIPT EXECUSION --
if reaper.CountTracks(0) ~= 0 then
    set_variables()
    get_selected_tracks()
    get_tracks_tab()
    gui_init()
    gui_loop()
else
    reaper.MB("No tracks in current project tab.\nPlease create at least one track.", "WARNING", 0)
end
