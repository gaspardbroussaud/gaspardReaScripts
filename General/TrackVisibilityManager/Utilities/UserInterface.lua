-- @noindex
-- @description Track Visibility Manager interface
-- @author gaspard
-- @about Complete user interface used in gaspard_Track Visibility Manager.lua script

local ctx = reaper.ImGui_CreateContext('track_manager_context')
local window_width = 550
local window_height = 350
local gui_W = window_width
local gui_H = window_height
local font = reaper.ImGui_CreateFont(style_font.style, style_font.size)
local small_font = reaper.ImGui_CreateFont(style_font.style, style_font.size * 0.75, reaper.ImGui_FontFlags_Italic())
local last_selected = -1
local show_settings = false
local changed = false
local direction = nil
local project_name = ""
local project_path = ""
local visible = false
local open = false
local is_one_track_solo = false
local one_changed = false

reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, small_font)
function Gui_Loop()
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    reaper.ImGui_SetNextWindowSize(ctx, gui_W, gui_H, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    -- F key shortcut
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_F()) then
        if not Settings.F_commandID.value then Settings.F_commandID.value = "" end
        reaper.Main_OnCommand(reaper.NamedCommandLookup(Settings.F_commandID.value), 0) -- Input command ID in Settings
    end

    -- If track count updates (delete or add track)
    if track_count ~= reaper.CountTracks(0) then
        System_GetTracksTable()
    end

    if Gui_CheckProjectChanged() or Gui_CheckTracksOrder() then
        System_ResetVariables()
        System_GetSelectedTracksTable()
        System_GetTracksTable()
    end

    if track_count > 0 then
        is_one_track_solo = System_UpdateSoloState()
    else
        is_one_track_solo = false
    end

    if visible then
        -- Top bar elements
        Gui_TopBar()

        if show_settings then
            Gui_SettingsWindow()
        end

        if track_count ~= 0 then
            Gui_TableTracks()
        else
            reaper.ImGui_Text(ctx, "Add tracks to begin.")
        end

        -- Show script version on  bottom right
        Gui_Version()

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
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, 30) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "Settings X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 40, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 40, 22) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            local push_color = false
            if show_settings then
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x9C91F2FF)
                push_color = true
            end
            if reaper.ImGui_Button(ctx, 'Settings##settings_button') then
                show_settings = not show_settings
                if one_changed then
                    gson.SaveJSON(settings_path, Settings)
                    one_changed = false
                end
            end
            if push_color then reaper.ImGui_PopStyleColor(ctx) end

            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'X##quit_button') then
                System_SetButtonState()
                open = false
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
    end
end

-- GUI ELEMENTS FOR TABLE TRACKS
function Gui_TableTracks()
    -- GUI Tracks Table
    local table_x, table_y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_flags = reaper.ImGui_WindowFlags_NoScrollbar()
    if reaper.ImGui_BeginChild(ctx, "child_scroll", table_x, table_y - (16 * 0.75) - 10, 0, child_flags) and track_count ~= 0 then
        local table_flags = reaper.ImGui_TableFlags_SizingFixedFit() | reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_ScrollY()
        if reaper.ImGui_BeginTable(ctx, "table_tracks", 3, table_flags) then

            reaper.ImGui_TableSetupScrollFreeze(ctx, 0, 1)

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
            local text_x, _ = reaper.ImGui_CalcTextSize(ctx, "ID")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
            reaper.ImGui_Text(ctx, "ID")

            reaper.ImGui_TableNextColumn(ctx)
            if Settings.show_mute_buttons.value or Settings.show_solo_buttons.value then
                x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                local t_x, _ = reaper.ImGui_CalcTextSize(ctx, "STATE")
                reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - t_x) * 0.5))
            end
            reaper.ImGui_Text(ctx, "STATE")

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, "TRACK NAME")

            -- Detect MacOS or Windows
            local ctrl_key = reaper.ImGui_Key_LeftCtrl()
            if not reaper.GetOS():match("Win") then ctrl_key = reaper.ImGui_Mod_Super() end
            -- CTRL + A Select all tracks
            if reaper.ImGui_IsKeyDown(ctx, ctrl_key) and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_A()) then
                for i = 0, #tracks do
                    tracks[i].select = true
                    if Settings.link_tcp_select.value then reaper.SetTrackSelected(tracks[i].id, true) end
                end
            end

            -- ESCAPE Key to unselect al tracks
            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
                for i = 0, #tracks do
                    tracks[i].select = false
                end
            end

            for i = 0, #tracks do
                if tracks[i].depth ~= reaper.GetTrackDepth(tracks[i].id) then
                    System_GetTracksTable()
                end

                if Settings.link_tcp_solo.value then
                    local solo = reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_SOLO")
                    if solo > 0 then tracks[i].solo = 1
                    else tracks[i].solo = 0 end
                end

                if is_one_track_solo then
                    local parent_track, parent_is_solo = System_IsParentSolo(tracks[i].id)
                    if tracks[i].solo < 1 and parent_is_solo then
                        local index = System_FindTrackInTracksTab(parent_track)
                        if index and not System_IsOneSubParentsSolo(index) then
                            tracks[i].solo = -1
                        end
                    end
                end

                if Settings.link_tcp_solo.value then
                    if tracks[i].solo < 1 and tracks[i].collapse ~= -1 then
                        if System_IsOneSubParentsSolo(i) and tracks[i].mute == 0 then tracks[i].solo = -1 end
                    end
                end

                if tracks[i].visible then
                    --#region Selectable item for multi edit
                    reaper.ImGui_TableNextRow(ctx)
                    reaper.ImGui_TableNextColumn(ctx)
                    x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                    text_x, _ = reaper.ImGui_CalcTextSize(ctx, tracks[i].number)
                    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
                    local selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap()

                    -- Link track selection between project and GUI
                    if Settings.link_tcp_select.value then tracks[i].select = reaper.IsTrackSelected(tracks[i].id) end

                    -- Selection element
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
                        if Settings.link_tcp_select.value then
                            if tracks[i].select then
                                reaper.SetTrackSelected(tracks[i].id, true)
                            else
                                reaper.SetTrackSelected(tracks[i].id, false)
                            end
                        end

                        last_selected = i

                        -- Link track selection between project and GUI
                        if Settings.link_tcp_select.value then reaper.SetTrackSelected(tracks[i].id, tracks[i].select) end
                    end
                    --#endregion

                    --#region Checkbox for visibility state
                    reaper.ImGui_TableNextColumn(ctx)
                    if not Settings.show_mute_buttons.value and not Settings.show_solo_buttons.value then
                        x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - 21) * 0.5))
                    end
                    changed, tracks[i].state = reaper.ImGui_Checkbox(ctx, "##checkbox"..tostring(i), tracks[i].state)
                    if changed then
                        reaper.PreventUIRefresh(1)
                        reaper.Undo_BeginBlock()

                        System_GetSelectedTracksTable()

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

                        System_SetSelectedTracksBack()

                        reaper.Undo_EndBlock("Tracks hidden or shown via Track Visibility Tool.", -1)
                        reaper.PreventUIRefresh(-1)
                        reaper.UpdateArrange()
                    end
                    --#endregion

                    --#region Mute button in GUI
                    if Settings.show_mute_buttons.value and Settings.link_tcp_mute.value then
                        local push_color = false
                        local push_color_light = false

                        reaper.ImGui_SameLine(ctx)

                        if tracks[i].mute == 1 then push_color = true
                        elseif tracks[i].depth > 0 and System_IsParentMute(tracks[i].id) or is_one_track_solo and tracks[i].solo == 0 then push_color_light = true end

                        if push_color then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xaa0000ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xcc0000ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x880000ff)
                        elseif push_color_light then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x360036ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xcc0000ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x880000ff)
                        end

                        if reaper.ImGui_Button(ctx, "M##mute_button"..tostring(i)) then
                            if reaper.ImGui_IsKeyDown(ctx, ctrl_key) then
                                reaper.Main_OnCommand(40339, 0) -- Unmute all tracks
                                for j = 0, #tracks do
                                    tracks[j].mute = 0
                                end
                            else
                                tracks[i].mute = math.abs(tracks[i].mute - 1)
                                if tracks[i].select then
                                    for j = 0, #tracks do
                                        if tracks[j].select then
                                            tracks[j].mute = tracks[i].mute
                                            reaper.SetMediaTrackInfo_Value(tracks[j].id, "B_MUTE", tracks[j].mute)
                                        end
                                    end
                                else
                                    reaper.SetMediaTrackInfo_Value(tracks[i].id, "B_MUTE", tracks[i].mute)
                                end
                            end
                        end

                        if push_color or push_color_light then reaper.ImGui_PopStyleColor(ctx, 3) end
                    end
                    --#endregion

                    --#region Solo button in GUI
                    if Settings.show_solo_buttons.value and Settings.link_tcp_solo.value then
                        local push_color = false
                        local push_color_light = false

                        reaper.ImGui_SameLine(ctx)

                        if tracks[i].solo == 1 then push_color = true
                        elseif tracks[i].mute == 0 and not System_IsParentMute(tracks[i].id) and tracks[i].solo == -1 then push_color_light = true end

                        if push_color then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xaaaa00ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xcccc00ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x888800ff)
                        elseif push_color_light then
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x363600ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xcccc00ff)
                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x888800ff)
                        end

                        if reaper.ImGui_Button(ctx, "S##solo_button"..tostring(i)) then
                            if reaper.ImGui_IsKeyDown(ctx, ctrl_key) then
                                reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
                                for j = 0, #tracks do
                                    tracks[j].solo = 0
                                end
                            else
                                tracks[i].solo = math.abs(tracks[i].solo - 1)
                                if tracks[i].select then
                                    for j = 0, #tracks do
                                        if tracks[j].select then
                                            tracks[j].solo = tracks[i].solo
                                            reaper.SetMediaTrackInfo_Value(tracks[j].id, "I_SOLO", tracks[j].solo)
                                        end
                                    end
                                else
                                    reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_SOLO", tracks[i].solo)
                                end
                            end
                        end

                        if push_color or push_color_light then reaper.ImGui_PopStyleColor(ctx, 3) end
                    end
                    --#endregion

                    --#region Arrow button for collapse
                    reaper.ImGui_TableNextColumn(ctx)
                    if reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERDEPTH") == 1 then
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10, 1)
                        reaper.ImGui_SameLine(ctx)

                        if Settings.link_tcp_collapse.value then
                            if tracks[i].collapse ~= reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT") then
                                System_UpdateTrackCollapse(i, reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT"))
                            end
                        end

                        if tracks[i].collapse > 1 then direction = reaper.ImGui_Dir_Right()
                        else direction = reaper.ImGui_Dir_Down() end

                        -- Arrow Button for folders
                        if reaper.ImGui_ArrowButton(ctx, "arrow"..tostring(i), direction) then
                            System_UpdateTrackCollapse(i, nil)
                            -- Set collapsed state for track if link enabled in settings
                            if Settings.link_tcp_collapse.value then reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse) end
                        end
                    else
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10 + 28, 1)
                        reaper.ImGui_SameLine(ctx)
                    end
                    --#endregion

                    --#region Text display for tracks name
                    reaper.ImGui_SameLine(ctx)
                    local _, text_cell = reaper.GetSetMediaTrackInfo_String(tracks[i].id, "P_NAME", "", false)
                    if text_cell == "" then text_cell = "Track "..tracks[i].number end

                    local push_color_mute = false
                    if Settings.link_tcp_mute.value then
                        tracks[i].mute = reaper.GetMediaTrackInfo_Value(tracks[i].id, "B_MUTE")

                        if tracks[i].mute == 1 then push_color_mute = true
                        elseif tracks[i].depth > 0 and System_IsParentMute(tracks[i].id) then push_color_mute = true
                        elseif is_one_track_solo and tracks[i].solo == 0 then push_color_mute = true end

                        if push_color_mute then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xefb7b7cc) end
                    end

                    reaper.ImGui_Text(ctx, tostring(text_cell))

                    if Settings.link_tcp_mute.value and push_color_mute then reaper.ImGui_PopStyleColor(ctx, 1) end
                    --#endregion
                end
            end
            reaper.ImGui_EndTable(ctx)
        end
        reaper.ImGui_EndChild(ctx)
    end
end

-- GUI ELEMENTS FOR SETTINGS WINDOW
function Gui_SettingsWindow()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar()
    local settings_width = gui_W - 180
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, gui_H - 170, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + window_width / 2 - settings_width / 2, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        local table_flags = reaper.ImGui_TableFlags_SizingFixedFit()
        if reaper.ImGui_BeginTable(ctx, "table_settings", 2, table_flags) then
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)

            -- Link Track Selection
            reaper.ImGui_Text(ctx, "Link Track Selection:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.link_tcp_select.value = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_select", Settings.link_tcp_select.value)
            if changed then one_changed = true end

            reaper.ImGui_TableNextColumn(ctx)

            -- Link Track Collapse
            reaper.ImGui_Text(ctx, "Link Track Collapse:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.link_tcp_collapse.value = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_collapse", Settings.link_tcp_collapse.value)
            if changed then one_changed = true end

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)

            -- Link Track Mute
            reaper.ImGui_Text(ctx, "Link Track Mute:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.link_tcp_mute.value = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_mute", Settings.link_tcp_mute.value)
            if changed then
                if not Settings.link_tcp_mute.value then
                    Settings.show_mute_buttons.value = false
                    Settings.link_tcp_solo.value = false
                    Settings.show_solo_buttons.value = false
                end
                one_changed = true
            end

            reaper.ImGui_TableNextColumn(ctx)

            -- Show Mute Buttons
            reaper.ImGui_Text(ctx, "Show Mute Buttons:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.show_mute_buttons.value = reaper.ImGui_Checkbox(ctx, "##checkbox_show_mute_buttons", Settings.show_mute_buttons.value)
            if changed then
                if Settings.show_mute_buttons.value then Settings.link_tcp_mute.value = true end
                one_changed = true
            end

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)

            -- Link Track Solo
            reaper.ImGui_Text(ctx, "Link Track Solo:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.link_tcp_solo.value = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_solo", Settings.link_tcp_solo.value)
            if changed then
                if Settings.link_tcp_solo.value then
                    Settings.link_tcp_mute.value = true
                else
                    Settings.show_solo_buttons.value = false
                end

                one_changed = true
            end

            reaper.ImGui_TableNextColumn(ctx)

            -- Show Solo Buttons
            reaper.ImGui_Text(ctx, "Show Solo Buttons:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.show_solo_buttons.value = reaper.ImGui_Checkbox(ctx, "##checkbox_show_solo_buttons", Settings.show_solo_buttons.value)
            if changed then
                if Settings.show_solo_buttons.value then
                    Settings.link_tcp_mute.value = true
                    Settings.link_tcp_solo.value = true
                end
                one_changed = true
            end

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)

            -- Custom Command ID for F shortcut
            reaper.ImGui_Text(ctx, "Custom F key command ID:")

            reaper.ImGui_TableNextColumn(ctx)

            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, Settings.F_commandID.value = reaper.ImGui_InputText(ctx, "##input_F_commandID", Settings.F_commandID.value)
            if changed then one_changed = true end

            reaper.ImGui_EndTable(ctx)
        end

        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        local button_x = 100
        if not one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x - 10)
        if reaper.ImGui_Button(ctx, "APPLY##apply_button", button_x) then
            gson.SaveJSON(settings_path, Settings)
            one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        if one_changed then
            gson.SaveJSON(settings_path, Settings)
            one_changed = false
        end
        show_settings = false
    end
end

-- Gui Version on bottom right
function Gui_Version()
    local text = "gaspard v"..version
    reaper.ImGui_PushFont(ctx, small_font)
    local w, h = reaper.ImGui_CalcTextSize(ctx, text)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_PopFont(ctx)
end

-- CHECK CURRENT PROJECT CHANGE
function Gui_CheckProjectChanged()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        return true
    else
        return false
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

-- PUSH ALL GUI STYLE SETTINGS
function Gui_PushTheme()
    -- Style Vars
    for i = 1, #style_vars do
        reaper.ImGui_PushStyleVar(ctx, style_vars[i].var, style_vars[i].value)
    end

    -- Style Colors
    for i = 1, #style_colors do
        reaper.ImGui_PushStyleColor(ctx, style_colors[i].col, style_colors[i].value)
    end
end

-- POP ALL GUI STYLE SETTINGS
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end
