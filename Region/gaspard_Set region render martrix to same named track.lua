-- @description Set region render martrix to same named track
-- @author gaspard
-- @version 1.1.2
-- @changelog
--  - Fix typo in variable name
-- @about
--  - Set region's render matrix track to track with same name.

---comment
---@param track any
---@return string name
-- GET TOP PARENT TRACK
function GetConcatenatedParentNames(track)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if Settings.region_naming_parent_casacde then
        while true do
            local parent = reaper.GetParentTrack(track)
            if parent then
                track = parent
                local _, parent_name = reaper.GetSetMediaTrackInfo_String(parent, "P_NAME", "", false)
                name = parent_name.."_"..name
            else
                return name
            end
        end
    else
        return name
    end
end

-- GET ALL TRACKS AND CONCANETATED PARENTS NAMES IN TABLE
function GetTracks()
    local track_count = reaper.CountTracks(0)
    if track_count > 0 then
        local tracks = {}
        for i = 0, track_count - 1 do
            local cur_track = reaper.GetTrack(0, i)
            local track_name = GetConcatenatedParentNames(cur_track)
            tracks[i] = { track = cur_track, name = track_name }
        end
        return tracks
    end
    return nil
end

-- SET RENDER REGION MATRIX WITH TRACKS INFOS
function SetRenderMatrixTracks()
    local _, _, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
        InitSystemVariables()
        local tracks = GetTracks()
        if tracks then
            missing = {}
            for i = 0, num_regions - 1 do
                local _, isrgn, _, _, name, index = reaper.EnumProjectMarkers2(0, i)
                if isrgn then
                    local should_look = true
                    if Settings.look_for_patterns and name:match(Settings.region_naming_pattern) and Settings.region_naming_pattern ~= "" then
                        should_look = false
                    end
                    if should_look then
                        table.insert(missing, { name = name, index = index })
                        for j = 0, #tracks do
                            if tracks[j].name == name then
                                reaper.SetRegionRenderMatrix(0, index, tracks[j].track, 1)
                                table.remove(missing, #missing)
                                break
                            end
                        end
                    end
                end
            end
            if #missing > 0 then
                Gui_Init()
                Gui_Loop()
            else
                reaper.ShowMessageBox("All regions have been set.", "Message box", 0)
            end
            --[[
            if #missing > 0 then
                local error_message = ""
                for i = 1, #missing do
                    error_message = error_message.." - "..tostring(missing[i].name).."; index: "..tostring(missing[i].index).."\n"
                end
                reaper.ShowConsoleMsg("\nThere are errors in region/track links.\nRegions affected:\n"..error_message)
            end
            ]]
        else
            reaper.ShowMessageBox("There are no tracks in current project.", "MESSAGE", 0)
        end
    else
        reaper.ShowMessageBox("There are no regions in current project.", "MESSAGE", 0)
    end
end

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("gaspard_json_lib")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_Set region render martrix to same named track_settings.json'
    Settings = {
        region_naming_parent_casacde = false,
        look_for_patterns = false,
        region_naming_pattern = ""
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

---------------------------------------------------------------------------------
-- Get GUI style from file
function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_vars = style.vars
    style_colors = style.colors
end

-- All initial variable for script and GUI
function InitialVariables()
    GetGuiStylesFromFile()
    version = "1.1"
    window_width = 350
    window_height = 200
    font_size = 16
    window_name = "Region render matrix linker"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    show_settings = false
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', font_size)
    reaper.ImGui_Attach(ctx, font)
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    local child_flags = reaper.ImGui_WindowFlags_NoScrollbar()
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, 30, reaper.ImGui_ChildFlags_None(), child_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "Settings X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 40, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 30, 22, reaper.ImGui_ChildFlags_None(), child_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'Settings##settings_button') then
                show_settings = not show_settings
            end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'X##quit_button') then
                open = false
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
    end
end

-- Gui Elements
function Gui_Elements()
    -- Set child section size (can use PushItemWidth for items without this setting) and center in window_width
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_example_elements", window_width - 20, window_height - 75, reaper.ImGui_ChildFlags_Border()) then
        if reaper.ImGui_BeginTable(ctx, "table_selectable_missing", 1, reaper.ImGui_TableFlags_BordersInner()) then
            reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(), 1, 5)
            for i = 1, #missing do
                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableNextColumn(ctx)
                local text = "Region "..tostring(missing[i].index)..": "..tostring(missing[i].name)
                local changed, _ = reaper.ImGui_Selectable(ctx, text.."##select_missing_"..tostring(i), false)
                if changed then
                    reaper.GoToRegion(0, missing[i].index, false)
                end
            end
            reaper.ImGui_PopStyleVar(ctx)
            reaper.ImGui_EndTable(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

-- Gui Version on bottom right
function Gui_Version()
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, "v"..version)
end

-- GUI ELEMENTS FOR SETTINGS WINDOW
function Gui_SettingsWindow()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar()
    local settings_width = window_width - 20
    local settings_height = window_height * 0.6
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        local one_changed = false
        reaper.ImGui_Text(ctx, "Name region using parent track cascade:")
        reaper.ImGui_SameLine(ctx)
        changed, Settings.region_naming_parent_casacde = reaper.ImGui_Checkbox(ctx, "##setting_naming_cascade", Settings.region_naming_parent_casacde)
        if changed then one_changed = true end

        reaper.ImGui_Text(ctx, "Look for pattern in name:")
        reaper.ImGui_SameLine(ctx)
        changed, Settings.look_for_patterns = reaper.ImGui_Checkbox(ctx, "##setting_name_pattern", Settings.look_for_patterns)
        if changed then one_changed = true end

        reaper.ImGui_Text(ctx, "Pattern:")
        reaper.ImGui_SameLine(ctx)
        if not Settings.look_for_patterns then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_PushItemWidth(ctx, -1)
        changed, Settings.region_naming_pattern = reaper.ImGui_InputText(ctx, "##setting_text_pattern", Settings.region_naming_pattern)
        if reaper.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, 'CAREFUL: Do not set pattern to only "-".') end
        if not Settings.look_for_patterns then reaper.ImGui_EndDisabled(ctx) end
        if changed then one_changed = true end

        if one_changed then gson.SaveJSON(settings_path, Settings) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        show_settings = false
    end
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- Settings window elements
        if show_settings then
            Gui_SettingsWindow()
        end

        -- All Gui Elements
        Gui_Elements()

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

-- Push all GUI style settings
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

-- Pop all GUI style settings
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

-- MAIN SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(-1)

SetRenderMatrixTracks()

reaper.PreventUIRefresh(1)
reaper.Undo_EndBlock("Set region render martrix to same name track", -1)
reaper.UpdateArrange()