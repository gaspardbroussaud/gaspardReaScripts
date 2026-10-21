-- @description Set region render matrix to same named track
-- @author gaspard
-- @version 1.0.7
-- @changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
-- @about
--  - Set region's render matrix track to track with same name.

---comment
---@param track any
---@return string name
-- GET TOP PARENT TRACK
function GetConcatenatedParentNames(track)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if Settings.region_naming_parent_casacde.value then
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

-- Remove empty lines from a string
function RemoveEmptyLines(text)
    local result = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line:match("%S") then table.insert(result, line) end
    end
    return table.concat(result, "\n")
end

-- Split a text string into lines
function SplitIntoLines(text)
    local lines = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

-- SET RENDER REGION MATRIX WITH TRACKS INFOS
function SetRenderMatrixTracks()
    local _, _, num_regions = reaper.CountProjectMarkers(0)
    if num_regions > 0 then
        InitSystemVariables()
        local tracks = GetTracks()
        if tracks then
            missing = {}
            local patterns = SplitIntoLines(Settings.region_naming_pattern.value)
            for i = 0, num_regions - 1 do
                local _, isrgn, _, _, name, index = reaper.EnumProjectMarkers2(0, i)
                if isrgn then
                    local should_look = true
                    if Settings.look_for_patterns.value and Settings.region_naming_pattern.value then
                        -- Go through splited lines of patterns
                        for _, pattern in ipairs(patterns) do
                            if name:lower():match(pattern:lower(), 1, true) then
                                should_look = false
                                break
                            end
                        end
                    end
                    if should_look then
                        table.insert(missing, { name = name, index = index })
                        for j = 0, #tracks do
                            if tracks[j].name == name:gsub("_(%d+)$", "") then
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
    gson = require("json_utilities_lib")
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = { "region_naming_parent_casacde", "look_for_patterns", "region_naming_pattern" },
        region_naming_parent_casacde = {
            value = false,
            name = "Region name from folder cascade",
            description = "Use cascading track folders to name regions."
        },
        look_for_patterns = {
            value = false,
            name = "Look for pattern in names",
            description = "Look for a specific pattern in region names to exclude region from linking."
        },
        region_naming_pattern = {
            value = "",
            multiline = {
                is_multiline = true,
                remove_empty_lines = true
            },
            char_type = nil,
            name = "Text pattern",
            description = 'Pattern to look for in region names. Can be regex.\nInput multiple patterns, one each line.\nCAREFUL: Do not set pattern to only "-".'
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

---------------------------------------------------------------------------------
-- gaspard GUI libraries: GUI style and GUI system (icon buttons)
GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

-- Get script version with ReaPack (fallback: @version of this file)
function GetScriptVersion()
    local script_path = select(2, reaper.get_action_context())
    if reaper.ReaPack_GetOwner then
        local pkg = reaper.ReaPack_GetOwner(script_path)
        if pkg then
            local pkg_version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
            reaper.ReaPack_FreeEntry(pkg)
            if pkg_version ~= "" and pkg_version ~= "nil" then return pkg_version end
        end
    end
    local file = io.open(script_path, "r")
    if file then
        local header = file:read(1024) or ""
        file:close()
        local file_version = header:match("@version%s+([%w%.]+)")
        if file_version then return file_version end
    end
    return "1.0.0"
end

-- All initial variable for script and GUI
function InitialVariables()
    version = GetScriptVersion()
    og_window_width = 400
    og_window_height = 300
    window_width = og_window_width
    window_height = og_window_height
    min_width, min_height = 300, 150
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    window_name = "REGION RENDER MATRIX LINKER"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    show_settings = false
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    italic_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
    icon_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, italic_font)
    reaper.ImGui_Attach(ctx, icon_font)
end

-- GUI Top Bar (GaspaReaLauncher style)
function Gui_TopBar()
    reaper.ImGui_BeginGroup(ctx)
    -- Name and version
    reaper.ImGui_Text(ctx, window_name)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, italic_font, font_size * 0.75)
    reaper.ImGui_Text(ctx, "v" .. version)
    reaper.ImGui_PopFont(ctx)

    -- Icon buttons (right to left)
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false})
    table.insert(menu, {icon = 'GEAR', hint = 'Settings', font = icon_font, size = icon_size, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

-- Gui Elements
function Gui_Elements()
    -- Set child section size (can use PushItemWidth for items without this setting) and center in window_width
    local _, child_height = reaper.ImGui_GetContentRegionAvail(ctx)
    reaper.ImGui_Indent(ctx, 2) -- 10px margin without SetCursorPos (needs no trailing item)
    if reaper.ImGui_BeginChild(ctx, "child_example_elements", window_width - 20, child_height, reaper.ImGui_ChildFlags_Borders()) then
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
    reaper.ImGui_Unindent(ctx, 2)
end

-- Settings panel (GaspaReaLauncher style: under top bar, right aligned, changes saved immediately)
function Gui_SettingsWindow()
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
        | reaper.ImGui_WindowFlags_TopMost() | reaper.ImGui_WindowFlags_NoDecoration() | reaper.ImGui_WindowFlags_AlwaysAutoResize()
    reaper.ImGui_SetNextWindowPos(ctx, window_x + window_width - 8, window_y + topbar_height + 5, reaper.ImGui_Cond_Always(), 1, 0)
    local settings_visible = reaper.ImGui_Begin(ctx, '##settings_window', true, settings_flags)
    if not settings_visible then
        show_settings = false
        return
    end

    reaper.ImGui_Text(ctx, "SETTINGS")
    reaper.ImGui_Separator(ctx)

    local changed
    local settings_changed = false
    changed, Settings.region_naming_parent_casacde.value = reaper.ImGui_Checkbox(ctx, Settings.region_naming_parent_casacde.name .. "##setting_naming_cascade", Settings.region_naming_parent_casacde.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.region_naming_parent_casacde.description)
    if changed then settings_changed = true end

    changed, Settings.look_for_patterns.value = reaper.ImGui_Checkbox(ctx, Settings.look_for_patterns.name .. "##setting_name_pattern", Settings.look_for_patterns.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.look_for_patterns.description)
    if changed then settings_changed = true end

    -- Pattern input depends on "look for patterns" setting
    if not Settings.look_for_patterns.value then reaper.ImGui_BeginDisabled(ctx) end
    reaper.ImGui_Text(ctx, Settings.region_naming_pattern.name .. ":")
    Settings.region_naming_pattern.value = RemoveEmptyLines(Settings.region_naming_pattern.value)
    _, Settings.region_naming_pattern.value = reaper.ImGui_InputTextMultiline(ctx, "##setting_text_pattern", Settings.region_naming_pattern.value, 280, font_size * 6)
    reaper.ImGui_SetItemTooltip(ctx, Settings.region_naming_pattern.description)
    if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
        Settings.region_naming_pattern.value = RemoveEmptyLines(Settings.region_naming_pattern.value)
        settings_changed = true
    end
    if not Settings.look_for_patterns.value then reaper.ImGui_EndDisabled(ctx) end

    if settings_changed then gson.SaveJSON(settings_path, Settings) end

    reaper.ImGui_End(ctx)
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
    -- Min size: title + version + icons must fit
    local min_w = math.max(min_width, reaper.ImGui_CalcTextSize(ctx, window_name) + 120)
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_w, min_height, math.huge, math.huge)
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
    for i = 1, #GUI_STYLE.VARS do
        reaper.ImGui_PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        reaper.ImGui_PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #GUI_STYLE.VARS)
    reaper.ImGui_PopStyleColor(ctx, #GUI_STYLE.COLORS)
end

-- MAIN SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(-1)

SetRenderMatrixTracks()

reaper.PreventUIRefresh(1)
reaper.Undo_EndBlock("Set region render matrix to same named track", -1)
reaper.UpdateArrange()