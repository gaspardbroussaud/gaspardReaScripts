--@description Set marker to first transient in selected items using name pattern
--@author gaspard
--@version 1.0
--@changelog
--  - Add script
--@about
--  - Set marker to first transient in selected items using name pattern
--  - How to use:
--      - Select items to insert markers
--      - Enter names in GUI
--      - Create markers with button

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

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = {"loop_on_pattern", "patterns"},
        loop_on_pattern = {
            value = false,
            name = "Loop on name list",
            description = 'Loop on items using patterns. With "pattern01, pattern02, pattern03", every 3 items it will reset to the first pattern in list.'
        },
        patterns = {
            value = "",
            multiline = {
                is_multiline = true,
                remove_empty_lines = true
            },
            char_type = nil,
            name = "Name list",
            description = 'Names for markers. Input multiple names, one each line.'
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- All initial variable for script and GUI
function InitialVariables()
    GetGuiStylesFromFile()
    InitSystemVariables()
    -- Get script version with Reapack
    local script_path = select(2, reaper.get_action_context())
    local pkg = reaper.ReaPack_GetOwner(script_path)
    version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
    reaper.ReaPack_FreeEntry(pkg)
    -- All script variables
    og_window_width = 275
    og_window_height = 285
    window_width = og_window_width
    window_height = og_window_height
    topbar_height = 30
    font_size = 16
    small_font_size = font_size * 0.75
    window_name = "MARKERS FOR ITEMS"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    settings_one_changed = false
end

-- Split a text string into lines
function SplitIntoLines(text)
    local lines = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    if #lines == 0 then lines = nil end
    return lines
end

-- Create marker at selected items start pos
function CreateMarkers(marker_names)
    local names = SplitIntoLines(marker_names)
    index = 1
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        name = ""
        replace_name = index <= #names
        if names and replace_name then
            name = tostring(names[index])
        end

        if replace_name then
            reaper.AddProjectMarker(0, false, start, 0, name, -1)
        end

        if names then
            index = index + 1
            if index > #names and Settings.loop_on_pattern.value then index = 1 end
        end
    end
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', font_size)
    small_font = reaper.ImGui_CreateFont('sans-serif', small_font_size, reaper.ImGui_FontFlags_Italic())
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, small_font)
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 35, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 35, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            --[[
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'Settings##settings_button') then
                show_settings = not show_settings
                if show_settings then
                    settings_loop_on_pattern = Settings.loop_on_pattern.value
                end
                if settings_one_changed then
                    settings_one_changed = false
                end
            end
            ]]--
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
    local child_main_x = window_width - 20
    local child_main_y = window_height - topbar_height - small_font_size - 30
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements", child_main_x, child_main_y) then
        reaper.ImGui_Text(ctx, Settings.loop_on_pattern.name..":")
        reaper.ImGui_SameLine(ctx)
        changed, Settings.loop_on_pattern.value = reaper.ImGui_Checkbox(ctx, "##checkbox_loop_on_patterns", Settings.loop_on_pattern.value)
        if changed then gson.SaveJSON(settings_path, Settings) end

        reaper.ImGui_Text(ctx, Settings.patterns.name..":")
        changed, Settings.patterns.value = reaper.ImGui_InputTextMultiline(ctx, "##multiline_patterns", Settings.patterns.value, -1, -1 - 30)
        if changed then gson.SaveJSON(settings_path, Settings) end

        item_count = reaper.CountSelectedMediaItems(0)
        disabled = item_count == 0
        if disable then reaper.ImGui_BeginDisabled(ctx) end

        if reaper.ImGui_Button(ctx, "CREATE##button_create_marker", 100) then
            reaper.Undo_BeginBlock()
            CreateMarkers(Settings.patterns.value)
            reaper.Undo_EndBlock('Set markers to selected items', -1)
            reaper.UpdateArrange()
        end

        if disable then
            reaper.ImGui_EndDisabled(ctx)
            reaper.ImGui_SetItemTooltip(ctx, "Please select at least one item.")
        end

        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Dummy(ctx, 1, 1)
end

function Gui_Settings()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar()
    local settings_width = og_window_width - 350
    local settings_height = og_window_height * 0.3
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        if reaper.ImGui_BeginChild(ctx, "child_settings_window", settings_width - 16, settings_height - 74, reaper.ImGui_ChildFlags_Border()) then
            reaper.ImGui_Text(ctx, Settings.loop_on_pattern.name)
            reaper.ImGui_SameLine(ctx)
            _, settings_loop_on_pattern = reaper.ImGui_Checkbox(ctx, "##checkbox_settings_loop_on_pattern", settings_loop_on_pattern)

            reaper.ImGui_Text(ctx, Settings.patterns.name)
            reaper.ImGui_SameLine(ctx)
            _, settings_patterns = reaper.ImGui_InputTextMultiline(ctx, "##input_multiline_patterns", settings_patterns)

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosX(ctx, settings_width - 80)
        reaper.ImGui_SetCursorPosY(ctx, settings_height - 35)
        if not settings_one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "Apply##settings_apply", 70) then
            Settings.loop_on_pattern.value = settings_loop_on_pattern
            Settings.patterns.value = settings_patterns
            gson.SaveJSON(settings_path, Settings)
            settings_one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        if settings_one_changed then
            ResetSettings()
            settings_one_changed = false
        end
        show_settings = false
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

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
