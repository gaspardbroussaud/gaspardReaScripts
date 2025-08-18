--@description Insert tracks with name inputs
--@author gaspard
--@version 1.0.2
--@changelog
--  - Fix font crash
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

-- Get GUI style from file
function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_font = style.font
    style_vars = style.vars
    style_colors = style.colors
end

-- All initial variable for script and GUI
function InitialVariables()
    GetGuiStylesFromFile()
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
    small_font_size = style_font.size * 0.75
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
    font = reaper.ImGui_CreateFont(style_font.style, style_font.size)
    small_font = reaper.ImGui_CreateFont(style_font.style, small_font_size, reaper.ImGui_FontFlags_Italic())
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

    reaper.ImGui_Dummy(ctx, 1, 1)
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
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
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
