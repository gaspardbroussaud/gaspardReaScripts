--@description Insert tracks with name inputs
--@author gaspard
--@version 1.0.5
--@changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
--@about
--  ###Insert tracks with name inputs
--  - How to use:
--      - Launch
--      - Enter names in GUI
--      - Create tracks with button

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- GUI style and GUI system (icon buttons) libraries
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
    -- All script variables
    og_window_width = 275
    og_window_height = 285
    min_width, min_height = 250, 200
    window_width = og_window_width
    window_height = og_window_height
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    small_font_size = font_size * 0.75
    icon_size = 22
    window_name = "TRACK INSERTOR"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
end

-- Split a text string into lines
function SplitIntoLines(text)
    local lines = {}
    for line in text:gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end
    local last_line = text:match("([^\n]*)$")
    if last_line ~= "" then
        table.insert(lines, last_line)
    end
    return lines
end

function CreateTracks(patterns)
    local names = SplitIntoLines(patterns)
    if names then
        for _, name in ipairs(names) do
            local track_count = reaper.CountTracks(0)
            reaper.InsertTrackInProject(0, track_count, 0)
            local track = reaper.GetTrack(0, track_count)
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
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
    reaper.ImGui_PushFont(ctx, italic_font, small_font_size)
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
    local child_main_x, child_main_y = reaper.ImGui_GetContentRegionAvail(ctx)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements", child_main_x, child_main_y, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then

        reaper.ImGui_Text(ctx, "Names (one each line):")
        changed, patterns_text = reaper.ImGui_InputTextMultiline(ctx, "##multiline_patterns", patterns_text, -1, -1 - 30)

        disabled = patterns_text == ""
        if disabled then reaper.ImGui_BeginDisabled(ctx) end

        if reaper.ImGui_Button(ctx, "CREATE##button_create_marker", 100) then
            reaper.Undo_BeginBlock()
            CreateTracks(patterns_text)
            reaper.Undo_EndBlock('Insert tracks with name inputs.', -1)
            reaper.UpdateArrange()
        end

        if disabled then
            reaper.ImGui_EndDisabled(ctx)
            reaper.ImGui_SetItemTooltip(ctx, "Please enter at least one name.")
        end

        reaper.ImGui_EndChild(ctx)
    end
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, math.huge, math.huge)
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
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
