-- @noindex
local ctx = reaper.ImGui_CreateContext('My script')
local window_name = ScriptName..'  -  '..ScriptVersion
local gui_W = 500
local gui_H = 300
local pin = false
local font = reaper.ImGui_CreateFont('sans-serif', 14)
local FLTMIN = reaper.ImGui_NumericLimits_Float()
local held_keys = {}
local last_selected = -1
local show_settings = false
local link_tcp_select = false
local link_tcp_collapse = true
local changed = false
local direction = nil
local project_name = ""
local project_path = ""
local update_track_collapse = false
local visible = false
local open = false

reaper.ImGui_Attach(ctx, font)
function Gui_Loop()
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollbar()
    if pin then
        window_flags = window_flags | reaper.ImGui_WindowFlags_TopMost()
    end
    reaper.ImGui_SetNextWindowSize(ctx, gui_W, gui_H, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)

    if Gui_ProjectChanged() or Gui_CheckTracksOrder() then
        System_SetVariables()
        System_GetSelectedTracksTable()
        System_GetTracksTable()
    end

    -- If track count updates (delete or add track)
    if track_count ~= reaper.CountTracks(0) then
        System_GetTracksTable()
    end

    Gui_CheckTrackCollapse()

    if visible then
        -- Top bar elements
        Gui_TopBar()
        
        if show_settings then
            Gui_SettingsWindow()
        end

        if track_count ~= 0 then
            Gui_TableTracks()
        end

        reaper.ImGui_End(ctx)
    end
    
    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui_Loop)
    end 
end

-- GUI ELEMENTS FOR TOP BAR
function Gui_TopBar()
    -- GUI Menu Bar
    local table_flags = reaper.ImGui_TableFlags_None() --reaper.ImGui_TableFlags_BordersOuter()
    if reaper.ImGui_BeginTable(ctx, "table_top_bar", 2, table_flags) then
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_TableNextColumn(ctx)
        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        local text_x, _ = reaper.ImGui_CalcTextSize(ctx, "SX")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (x - text_x - 24))
        
        if reaper.ImGui_Button(ctx, "S") then
            show_settings = not show_settings
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "X") then
            System_SetButtonState()
            open = false
        end

        reaper.ImGui_EndTable(ctx)
    end
end

-- GUI ELEMENTS FOR TABLE TRACKS
function Gui_TableTracks()
    -- GUI Tracks Table
    local x, y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_flags = reaper.ImGui_WindowFlags_NoScrollbar()
    if reaper.ImGui_BeginChild(ctx, "child_scroll", x, y, 0, child_flags) and track_count ~= 0 then
        local table_flags = reaper.ImGui_TableFlags_SizingFixedFit() | reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_ScrollY()
        if reaper.ImGui_BeginTable(ctx, "table_tracks", 3, table_flags) then

            reaper.ImGui_TableSetupScrollFreeze(ctx, 0, 1)

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            local text_x, _ = reaper.ImGui_CalcTextSize(ctx, "ID")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
            reaper.ImGui_Text(ctx, "ID")
            
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, "STATE")
            
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, "TRACK NAME")
            
            for i = 0, #tracks do
                if tracks[i].visible then
                    reaper.ImGui_TableNextRow(ctx)
                    reaper.ImGui_TableNextColumn(ctx)
                    x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                    local text_x, _ = reaper.ImGui_CalcTextSize(ctx, tracks[i].number)
                    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
                    local selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap()
                    x, y = reaper.ImGui_GetContentRegionAvail(ctx)
                    changed, tracks[i].select = reaper.ImGui_Selectable(ctx, tracks[i].number, tracks[i].select, selectable_flags, 0, 21)
                    if changed then
                        -- Get key press CTRL = 4096 or CMD = 32768 / SHIFT = 8192
                        local key_code = reaper.ImGui_GetKeyMods(ctx)
                        local ctrl, shift = false, false
                        if key_code == 4096 or key_code == 32768 then ctrl = true
                        elseif key_code == 8192 then shift = true end
                        
                        -- Multi selection system
                        if not ctrl and not shift then
                            if not tracks[i].select then
                                for j = 0, #tracks do
                                    if tracks[j].select then
                                        System_SetTrackVisibility(i, true)
                                    end
                                end
                            end
                            
                            for j = 0, #tracks do
                                if tracks[i].select == tracks[j].select and i ~= j then
                                    System_SetTrackVisibility(j, false)
                                end
                            end
                        end
                        
                        if not ctrl and shift then
                            for j = 0, #tracks do
                                if last_selected < j and j < i then
                                    System_SetTrackVisibility(j, true)
                                end
                                if last_selected > j and j > i then
                                    System_SetTrackVisibility(j, true)
                                end
                            end
                        end
                        
                        -- Set track visibility
                        if link_tcp_select then
                            if tracks[i].select then
                                reaper.SetTrackSelected(tracks[i].id, true)
                            else
                                reaper.SetTrackSelected(tracks[i].id, false)
                            end
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
                                        System_ShowTrack(tracks[j].id)
                                    else
                                        System_HideTrack(tracks[j].id)
                                    end
                                end
                            end
                        else
                            if tracks[i].state then
                                System_ShowTrack(tracks[i].id)
                            else
                                System_HideTrack(tracks[i].id)
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
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10, 1)
                        reaper.ImGui_SameLine(ctx)

                        if tracks[i].collapse > 1 then direction = reaper.ImGui_Dir_Right()
                        else direction = reaper.ImGui_Dir_Down() end
                        if reaper.ImGui_ArrowButton(ctx, "arrow"..tostring(i), direction) then
                            if tracks[i].collapse > 1 then
                                tracks[i].collapse = 0
                                if link_tcp_collapse then
                                    reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse)
                                end
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
                                if link_tcp_collapse then
                                    reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse)
                                end
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
                    else
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10 + 28, 1)
                        reaper.ImGui_SameLine(ctx)
                    end

                    reaper.ImGui_SameLine(ctx)
                    local _, text_cell = reaper.GetSetMediaTrackInfo_String(tracks[i].id, "P_NAME", "", false)
                    
                    if text_cell == "" then text_cell = "Track "..tracks[i].number end
                    reaper.ImGui_Text(ctx, tostring(text_cell))
                end
            end
            reaper.ImGui_EndTable(ctx)
        end
        reaper.ImGui_EndChild(ctx)
    end
end

-- GUI ELEMENTS FOR SETTINGS WINDOW
function Gui_SettingsWindow()
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x000000ff)
    -- Set Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, 400, 200, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + 50, window_y + 50, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        reaper.ImGui_Text(ctx, "Link Track Selection:")
        reaper.ImGui_SameLine(ctx)
        _, link_tcp_select = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_select", link_tcp_select)

        reaper.ImGui_Text(ctx, "Link Track Collapse:")
        reaper.ImGui_SameLine(ctx)
        _, link_tcp_collapse = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_collapse", link_tcp_collapse)

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        show_settings = false
    end
    reaper.ImGui_PopStyleColor(ctx, 1)
end

function Gui_PushTheme()
    -- Vars
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),   6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),    6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),    6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),    6)
    -- Colors
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x111111FF)
end

function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, 4)
    reaper.ImGui_PopStyleColor(ctx, 1)
end

-- CHECK CURRENT PROJECT CHANGE
function Gui_ProjectChanged()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        return true
    else
        return false
    end
end

-- CHECK FOR TRACK COLLAPSE CHANGE IN PROJECT
function Gui_CheckTrackCollapse()
    if reaper.CountTracks(0) ~= 0 and link_tcp_collapse then
        for i = 0, reaper.CountTracks(0) - 1 do
            if tracks[i].collapse ~= reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), "I_FOLDERCOMPACT") then
                tracks[i].collapse = reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), "I_FOLDERCOMPACT")
                System_UpdateTrackCollapse()
            end
        end
    end
end

-- CHECK FOR TRACK ORDER
function Gui_CheckTracksOrder()
    if reaper.CountTracks(0) ~= 0 then
        for i = 0, #tracks do
            local number = tostring(reaper.GetMediaTrackInfo_Value(tracks[i].id, "IP_TRACKNUMBER")):sub(1, -3)

            if number ~= tracks[i].number then
                return true
            end
        end
    end
    return false
end
