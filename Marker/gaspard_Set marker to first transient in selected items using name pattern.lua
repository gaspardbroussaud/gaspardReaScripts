--@description Set marker to first transient in selected items using name pattern
--@author gaspard
--@version 1.0.5
--@changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
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
    InitSystemVariables()
    version = GetScriptVersion()
    -- All script variables
    og_window_width = 275
    og_window_height = 285
    window_width = og_window_width
    window_height = og_window_height
    min_width, min_height = 250, 200
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    window_name = "MARKERS FOR ITEMS"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
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
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

-- Gui Elements
function Gui_Elements()
    local child_main_x = window_width - 20
    local _, child_main_y = reaper.ImGui_GetContentRegionAvail(ctx)
    reaper.ImGui_Indent(ctx, 2) -- 10px margin without SetCursorPos (needs no trailing item)
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
        if disabled then reaper.ImGui_BeginDisabled(ctx) end

        if reaper.ImGui_Button(ctx, "CREATE##button_create_marker", 100) then
            reaper.Undo_BeginBlock()
            CreateMarkers(Settings.patterns.value)
            reaper.Undo_EndBlock('Set markers to selected items', -1)
            reaper.UpdateArrange()
        end

        if disabled then
            reaper.ImGui_EndDisabled(ctx)
            reaper.ImGui_SetItemTooltip(ctx, "Please select at least one item.")
        end

        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_Unindent(ctx, 2)
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

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
