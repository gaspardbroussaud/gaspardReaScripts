--@noindex
--@description Complete renamer
--@author gaspard
--@version 0.0.1
--@changelog
--  - Initial release
--@about
--  ### Complete renamer
--  - A simple and quick renamer for tracks, regions, markers, items, etc

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

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
    version = "0.0.1"
    window_width = 500
    window_height = 400
    topbar_height = 30
    font_size = 16
    small_font_size = font_size * 0.75
    window_name = "COMPLETE RENAMER"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', 16)
    small_font = reaper.ImGui_CreateFont('sans-serif', 16 * 0.75, reaper.ImGui_FontFlags_Italic())
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, small_font)
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, 30, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 30, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 30, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
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
    local child_width = window_width - 20
    local child_height = window_height - topbar_height - small_font_size - 30
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_all_elements", child_width, child_height, reaper.ImGui_ChildFlags_Border(), no_scrollbar_flags) then
        local inner_child_width = child_width - 15
        if reaper.ImGui_BeginChild(ctx, "child_target_settings", inner_child_width, 24, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_SetCursorPosX(ctx, -30)
            reaper.ImGui_Checkbox(ctx, "##checkbox_empty_dummy", true)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Items:")
            reaper.ImGui_SameLine(ctx)
            changed, replace_items = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_items", replace_items)

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Tracks:")
            reaper.ImGui_SameLine(ctx)
            changed, replace_tracks = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_tracks", replace_tracks)

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Markers:")
            reaper.ImGui_SameLine(ctx)
            changed, replace_markers = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_markers", replace_markers)

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Regions:")
            reaper.ImGui_SameLine(ctx)
            changed, replace_regions = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_regions", replace_regions)

            reaper.ImGui_EndChild(ctx)
        end

        if reaper.ImGui_BeginChild(ctx, "child_replace_texts", inner_child_width, 50, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Text(ctx, "Find:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, input_find = reaper.ImGui_InputText(ctx, "##inputtext_find", input_find)
            reaper.ImGui_PopItemWidth(ctx)

            reaper.ImGui_Text(ctx, "Replace:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, input_replace = reaper.ImGui_InputText(ctx, "##inputtext_replace", input_replace)
            reaper.ImGui_PopItemWidth(ctx)

            reaper.ImGui_EndChild(ctx)
        end

        if reaper.ImGui_BeginChild(ctx, "child_preview_replace", inner_child_width, child_height - 24 - 50 - 50) then
            reaper.ImGui_Text(ctx, "[WIP rename preview]\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n[WIP]")

            reaper.ImGui_EndChild(ctx)
        end

        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        local button_x = 100
        local disable = false
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x)
        if reaper.ImGui_Button(ctx, "APPLY##apply_button", button_x) then
            reaper.ShowConsoleMsg("Apply rename\n")
            FindAndReplace("", "")
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_EndChild(ctx)
    end
end

-- Gui Version on bottom right
function Gui_Version()
    reaper.ImGui_PushFont(ctx, small_font)
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)
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

---------------------------------------------------

-- Get all items from project in table
function GetItemsFromProject()
    local items = {}
    if replace_items then
        local item_count = reaper.CountMediaItems(0)
        for i = 0, item_count - 1 do
            local item_id = reaper.GetMediaItem(0, i)
            local _, item_name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item_id, 0), "P_NAME", "", false)
            table.insert(items, { id = item_id, name = item_name })
        end
    end
    return items
end

-- Get all tracks from project in table
function GetTracksFromProject()
    local tracks = {}
    if replace_tracks then
        local track_count = reaper.CountTracks(0)
        for i = 0, track_count - 1 do
            local track_id = reaper.GetTrack(0, i)
            local _, track_name = reaper.GetTrackName(track_id)
            table.insert(tracks, { id = track_id, name = track_name })
        end
    end
    return tracks
end

-- Get all markers from project in table
function GetMarkersRegionsFromProject()
    local markers = {}
    local regions = {}
    if replace_markers or replace_regions then
        local _, marker_count, region_count = reaper.CountProjectMarkers(0)
        for i = 0, marker_count + region_count - 1 do
            local _, isrgn, _, _, enum_name, index = reaper.EnumProjectMarkers2(0, i)
            if isrgn then
                if replace_regions then table.insert(regions, { id = index, name = enum_name }) end
            else
                if replace_markers then table.insert(markers, { id = index, name = enum_name }) end
            end
        end
    end
    return markers, regions
end

-- Check all selected data to find and replace
function FindAndReplace(find_text, replace_text)
    local items = GetItemsFromProject()
    local tracks = GetTracksFromProject()
    local markers, regions = GetMarkersRegionsFromProject()
    local tables = {items, tracks, markers, regions}
    reaper.ShowConsoleMsg(tostring(#tables).."\n")

    for _, table in ipairs(tables) do
        for _, userdata in ipairs(table) do
            reaper.ShowConsoleMsg(tostring(userdata.name).."\n")
        end
    end
    reaper.ShowConsoleMsg("\n")
end

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
