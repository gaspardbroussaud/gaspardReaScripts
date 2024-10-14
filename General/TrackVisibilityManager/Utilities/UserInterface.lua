-- @noindex
-- @description Track Visibility Manager interface
-- @author gaspard
-- @about Complete user interface used in gaspard_Track Visibility Manager.lua script

local ctx = reaper.ImGui_CreateContext('My script')
local window_name = ScriptName..'  -  '..ScriptVersion
local window_width = 500
local window_height = 300
local gui_W = 500
local gui_H = 300
local font = reaper.ImGui_CreateFont('sans-serif', 15)
local last_selected = -1
local show_settings = false
local changed = false
local direction = nil
local project_name = ""
local project_path = ""
local visible = false
local open = false

reaper.ImGui_Attach(ctx, font)
function Gui_Loop()
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, gui_W, gui_H, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    -- If track count updates (delete or add track)
    if track_count ~= reaper.CountTracks(0) then
        System_GetTracksTable()
    end

    if Gui_CheckProjectChanged() or Gui_CheckTracksOrder() then
        System_SetVariables()
        System_GetSelectedTracksTable()
        System_GetTracksTable()
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

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "O X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 40, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", 60, 22) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'O##settings_button') then
                show_settings = not show_settings
            end

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
    if reaper.ImGui_BeginChild(ctx, "child_scroll", table_x, table_y, 0, child_flags) and track_count ~= 0 then
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
            reaper.ImGui_Text(ctx, "STATE")

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, "TRACK NAME")

            for i = 0, #tracks do
                if tracks[i].depth ~= reaper.GetTrackDepth(tracks[i].id) then
                    System_GetTracksTable()
                end

                if tracks[i].visible then
                    reaper.ImGui_TableNextRow(ctx)
                    reaper.ImGui_TableNextColumn(ctx)
                    x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                    text_x, _ = reaper.ImGui_CalcTextSize(ctx, tracks[i].number)
                    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - text_x) * 0.5))
                    local selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowOverlap()
                    -- Link track selection between project and GUI
                    if link_tcp_select then tracks[i].select = reaper.IsTrackSelected(tracks[i].id) end
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
                        if link_tcp_select then
                            if tracks[i].select then
                                reaper.SetTrackSelected(tracks[i].id, true)
                            else
                                reaper.SetTrackSelected(tracks[i].id, false)
                            end
                        end

                        last_selected = i

                        -- Link track selection between project and GUI
                        if link_tcp_select then reaper.SetTrackSelected(tracks[i].id, tracks[i].select) end
                    end

                    reaper.ImGui_TableNextColumn(ctx)
                    x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + ((x - 21) * 0.5))
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

                    reaper.ImGui_TableNextColumn(ctx)
                    if reaper.GetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERDEPTH") == 1 then
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10, 1)
                        reaper.ImGui_SameLine(ctx)

                        if link_tcp_collapse then
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
                            if link_tcp_collapse then reaper.SetMediaTrackInfo_Value(tracks[i].id, "I_FOLDERCOMPACT", tracks[i].collapse) end
                        end
                    else
                        reaper.ImGui_Dummy(ctx, tracks[i].depth * 10 + 28, 1)
                        reaper.ImGui_SameLine(ctx)
                    end

                    reaper.ImGui_SameLine(ctx)
                    local _, text_cell = reaper.GetSetMediaTrackInfo_String(tracks[i].id, "P_NAME", "", false)
                    if text_cell == "" then text_cell = "Track "..tracks[i].number end

                    local push_color = false
                    if link_tcp_mute then
                        tracks[i].mute = reaper.GetMediaTrackInfo_Value(tracks[i].id, "B_MUTE")
                        if tracks[i].mute == 1 then push_color = true
                        elseif tracks[i].depth > 0 and System_IsParentMute(tracks[i].id) then push_color = true end

                        if push_color then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xefb7b7cc) end
                    end

                    reaper.ImGui_Text(ctx, tostring(text_cell))

                    if link_tcp_mute and push_color then reaper.ImGui_PopStyleColor(ctx, 1) end
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
    reaper.ImGui_SetNextWindowSize(ctx, gui_W - 100, gui_H - 100, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + window_width / 2 - (gui_W - 100) / 2, window_y + 25, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        reaper.ImGui_Text(ctx, "Link Track Selection:")
        reaper.ImGui_SameLine(ctx)
        changed, link_tcp_select = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_select", link_tcp_select)
        if changed then System_WriteSettingsFile(link_tcp_select, link_tcp_collapse, link_tcp_mute) end

        reaper.ImGui_Text(ctx, "Link Track Collapse:")
        reaper.ImGui_SameLine(ctx)
        changed, link_tcp_collapse = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_collapse", link_tcp_collapse)
        if changed then System_WriteSettingsFile(link_tcp_select, link_tcp_collapse, link_tcp_mute) end

        reaper.ImGui_Text(ctx, "Link Track Mute:")
        reaper.ImGui_SameLine(ctx)
        changed, link_tcp_mute = reaper.ImGui_Checkbox(ctx, "##checkbox_link_tcp_mute", link_tcp_mute)
        if changed then System_WriteSettingsFile(link_tcp_select, link_tcp_collapse, link_tcp_mute) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        show_settings = false
    end
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
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 6)

    -- Style Colors
    -- Backgrounds
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x14141BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x14141BFF) --Added
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(), 0x1F1F28FF)

    -- Bordures
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x594A8C4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(), 0x0000003D)

    -- Texte
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(), 0x808080FF)

    -- En-têtes (Headers)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x23232BAF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x2C2D39AF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), 0x272734AF)

    -- Boutons
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x574F8EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x7C71C2FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x6B60B5FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0xFFFFFFFF)

    -- Popups
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), 0x14141B99)

    -- Curseur (Slider)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), 0x796BB6FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), 0x9A8BE1FF)

    -- Fond de cadre (Frame BG)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x2C2D39FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x272734FF)

    -- Onglets (Tabs)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0x3B2F66FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(), 0x312652FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocused(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocusedActive(), 0x23232BFF)

    -- Titre
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), 0x23232BFF)

    -- Scrollbar
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), 0x14141BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(), 0x1F1F28FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0x2C2D39FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(), 0x3B2F66FF)

    -- Séparateurs
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0x594A8CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(), 0x796BB6FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(), 0x9A8BE1FF)

    -- Redimensionnement (Resize Grip)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(), 0x594A8C4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x796BB64A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(), 0x9A8BE14A)

    -- Docking
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(), 0x796BB6FF)
end

-- POP ALL GUI STYLE SETTINGS
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, 4)
    reaper.ImGui_PopStyleColor(ctx, 39)
end
