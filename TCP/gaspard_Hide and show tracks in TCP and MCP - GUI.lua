-- @description Hide and show tracks in TCP and MCP - GUI
-- @author gaspard
-- @version 1.0.7
-- @changelog WIP : Fixed folder indent + fixed collapse.
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- SHOW IMGUI DEMO --
--reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS6b4644d86854e10895485f184942fb69ecc26177"), 0)

-- IMGUI STYLE VARIABLES PUSH AND POP --
function push_global_imgui_style()
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),   6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),    6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),    6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),    6)
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x11111111FF)
end

function pop_global_imgui_style()
    reaper.ImGui_PopStyleVar(ctx, 4)
    
    reaper.ImGui_PopStyleColor(ctx, 1)
end

-- SET SCRIPT STATE --
function set_button_state(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- SET ALL GLOBAL VARIABLES --
function set_variables()
    last_selected = -1
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    show_next_tracks = true
end

function quit_app()
    set_selected_tracks()

    set_button_state()
    
    window_open = false
end

function project_changed()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        return true
    else
        return false
    end
end

-- SET TRACK TO FALSE OR TRUE WITH INDEX --
function set_track_visibility(index, visibility)
    tracks[index].select = visibility
    reaper.SetTrackSelected(tracks[index].id, visibility)
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
        reaper.SetTrackSelected(tracks[i].id, false)
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

-- GET TOP PARENT TRACK --
local function get_top_parent_track(track)
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
function get_tracks_tab()
    track_count = reaper.CountTracks(0)

    -- Get all tracks and extract datas --
    tracks = {}
    local parent_check = false
    local inner_depth = 0.0
    for i = 0, track_count - 1 do
        local track_id = reaper.GetTrack(0, i)
        local track_state = reaper.GetMediaTrackInfo_Value(track_id, "B_SHOWINTCP")
        local track_select = reaper.IsTrackSelected(track_id)
        local track_collapse = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERCOMPACT")
        local track_depth = reaper.GetMediaTrackInfo_Value(track_id, "I_FOLDERDEPTH")
        --local track_top_parent = get_top_parent_track(track_id)


        if not reaper.GetParentTrack(track_id) then inner_depth = 0 end
        local cur_depth = inner_depth
        if track_depth > 0 then inner_depth = inner_depth + 1
        elseif track_depth < 0 then inner_depth = inner_depth - 1 end
        track_depth = cur_depth

        local track_visible = true

        tracks[i] = { id = track_id, state = track_state, select = track_select, collapse = track_collapse, depth = cur_depth, visible = track_visible }
    end
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
-- Top bar elements --
function gui_elements_top_bar()
    table_flags = reaper.ImGui_TableFlags_None() --reaper.ImGui_TableFlags_BordersOuter()
    if reaper.ImGui_BeginTable(ctx, "table_top_bar", 2, table_flags) then
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "TRACKS VISIBILITY STATE")
        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_TableNextColumn(ctx)
        x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        text_x, _ = reaper.ImGui_CalcTextSize(ctx, "X")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (x - text_x - 8))
        if reaper.ImGui_Button(ctx, "X") then
            quit_app()
        end

        reaper.ImGui_EndTable(ctx)
    end
end

-- Child for elements and scroll --
function gui_elements_child()
    x, y = reaper.ImGui_GetContentRegionAvail(ctx)
    child_flags = reaper.ImGui_WindowFlags_NoScrollbar()
    if reaper.ImGui_BeginChild(ctx, "child_scroll", x, y, 0, child_flags) then
        gui_elements_table()

        reaper.ImGui_EndChild(ctx)
    end
end

-- Table of tracks elements --
function gui_elements_table() 
    table_flags = reaper.ImGui_TableFlags_SizingFixedFit() | reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_ScrollY()
    if reaper.ImGui_BeginTable(ctx, "table_tracks", 4, table_flags) then

        reaper.ImGui_TableSetupScrollFreeze(ctx, 0, 1)

        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "ID")
        
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "STATE")

        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "")
        
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "TRACK NAME")
        
        for i = 0, #tracks do
            if tracks[i].visible then
                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableNextColumn(ctx)
                track_number = tostring(reaper.GetMediaTrackInfo_Value(tracks[i].id, "IP_TRACKNUMBER")):sub(1, -3)
                x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                text_x, _ = reaper.ImGui_CalcTextSize(ctx, track_number)
                reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
                selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap()
                x, y = reaper.ImGui_GetContentRegionAvail(ctx)
                changed, tracks[i].select = reaper.ImGui_Selectable(ctx, track_number, tracks[i].select, selectable_flags, 0, 21)
                if changed then
                    -- Get key press CTRL = 4096 or CMD = 32768 / SHIFT = 8192 --
                    key_code = reaper.ImGui_GetKeyMods(ctx)
                    ctrl, shift = false, false
                    if key_code == 4096 or key_code == 32768 then ctrl = true
                    elseif key_code == 8192 then shift = true end
                    
                    -- Multi selection system --
                    if not ctrl and not shift then
                        if not tracks[i].select then
                            for j = 0, #tracks do
                                if tracks[j].select then
                                    set_track_visibility(i, true)
                                end
                            end
                        end
                        
                        for j = 0, #tracks do
                            if tracks[i].select == tracks[j].select and i ~= j then
                                set_track_visibility(j, false)
                            end
                        end
                    end
                    
                    if not ctrl and shift then
                        for j = 0, #tracks do
                            if last_selected < j and j < i then
                                set_track_visibility(j, true)
                            end
                            if last_selected > j and j > i then
                                set_track_visibility(j, true)
                            end
                        end
                    end
                    
                    -- Set track visibility --
                    if tracks[i].select then
                        reaper.SetTrackSelected(tracks[i].id, true)
                    else
                        reaper.SetTrackSelected(tracks[i].id, false)
                    end
                    
                    last_selected = i
                end
                
                reaper.ImGui_TableNextColumn(ctx)
                x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - 21) * 0.5))
                changed, tracks[i].state = reaper.ImGui_Checkbox(ctx, "##checkbox"..tostring(i), tracks[i].state)
                if changed then
                    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

                    if tracks[i].select then
                        for j = 0, #tracks do
                            if tracks[j].select then
                                if tracks[i].state then
                                    show_track(tracks[j].id)
                                else
                                    hide_track(tracks[j].id)
                                end
                            end
                        end
                    else
                        if tracks[i].state then
                            show_track(tracks[i].id)
                        else
                            hide_track(tracks[i].id)
                        end
                    end

                    for j = 0, #tracks do
                        tracks[j].state = reaper.GetMediaTrackInfo_Value(tracks[j].id, "B_SHOWINTCP")
                    end

                    for j = 0, #tracks do
                        if tracks[j].select then
                            reaper.SetTrackSelected(tracks[j].id, true)
                        end
                    end
                end
                
                reaper.ImGui_TableNextColumn(ctx)
                if reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERDEPTH") == 1 then
                    if tracks[i].collapse > 1 then direction = reaper.ImGui_Dir_Right()
                    else direction = reaper.ImGui_Dir_Down() end
                    if reaper.ImGui_ArrowButton(ctx, "arrow"..tostring(i), direction) then
                        if tracks[i].collapse > 1 then
                            tracks[i].collapse = 0
                            reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse)
                            local out = false
                            local first = tracks[i].depth
                            for j = i + 1, #tracks do
                                if not out then
                                    if tracks[j].depth == 0 or tracks[j].depth <= first then
                                        out = true
                                    else
                                        tracks[j].visible = true
                                    end
                                end
                            end
                        else
                            tracks[i].collapse = 2
                            reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse)
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
                    end
                end

                reaper.ImGui_TableNextColumn(ctx)
                _, text_cell = reaper.GetSetMediaTrackInfo_String(tracks[i].id, "P_NAME", "", false)
                
                if text_cell == "" then text_cell = "Track "..track_number end
                
                space = ""
                if tracks[i].depth ~= 0 then
                    for j = 0, math.abs(tracks[i].depth) - 1 do
                        space = space.."    "
                    end
                    space = space.." |"
                else
                    space = " |"
                end
                
                text_cell = space..text_cell--.." | "..tostring(tracks[i].depth)
                reaper.ImGui_Text(ctx, tostring(text_cell))
            end
        end
        reaper.ImGui_EndTable(ctx)
    end
end

-- GUI LOOP --
function gui_loop()
    -- Set global style variables of ImGui --
    push_global_imgui_style()
    
    -- Set Window visibility and settings --
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, 500, 300, reaper.ImGui_Cond_Once())
    reaper.ImGui_PushFont(ctx, FONT)

    window_visible, window_open  = reaper.ImGui_Begin(ctx, 'TRACKS VISIBILITY STATE', true, window_flags)
    
    if project_changed() then
        set_variables()
        get_selected_tracks()
        get_tracks_tab()
    end
    
    if window_visible then
        -- If track count updates (delete or add track) --
        if track_count ~= reaper.CountTracks(0) then
            get_tracks_tab()
        end

        --[[for i = 0, track_count - 1 do
            local cur_collapse = reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT")
            if cur_collapse ~= tracks[i].collapse then
                tracks[i].collapse = cur_collapse
            end
        end]]
        
        -- Gui elements to display --
        gui_elements_top_bar()
        
        if reaper.CountTracks(0) ~= 0 then
            gui_elements_child()
        end
        
        reaper.ImGui_End(ctx)
    end 
    
    pop_global_imgui_style()
    reaper.ImGui_PopFont(ctx)

    if window_open then
        reaper.defer(gui_loop)
    else
        quit_app()
    end
end

-- MAIN SCRIPT EXECUSION --
set_button_state(1)
set_variables()
get_selected_tracks()
get_tracks_tab()
gui_init()
gui_loop()
reaper.atexit(set_button_state)
