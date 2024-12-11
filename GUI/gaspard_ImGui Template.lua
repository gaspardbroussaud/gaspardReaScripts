--@noindex
--@description ImGui Template
--@author gaspard
--@version 1.0
--@changelog
--  - Updates to script
--@about
--  ### Title
--  - All infos for user

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
    version = "1.0"
    og_window_width = 250
    og_window_height = 235
    window_width = og_window_width
    window_height = og_window_height
    topbar_height = 30
    font_size = 16
    small_font_size = font_size * 0.75
    window_name = "TEMPLATE IMGUI"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    settings_one_changed = false
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

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "Settings X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 40, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 40, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'Settings##settings_button') then
                show_settings = not show_settings
                if settings_one_changed then
                    --gson.SaveJSON(settings_path, Settings)
                    settings_one_changed = false
                end
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
    local child_main_x = window_width - 20
    local child_main_y = window_height - topbar_height - small_font_size - 30
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_example_elements", child_main_x, child_main_y) then
        reaper.ImGui_Text(ctx, "Text example")

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_TextDisabled(ctx, "(?)")

        if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
            reaper.ImGui_SetTooltip(ctx, "Tooltip example.")
        end

        reaper.ImGui_Dummy(ctx, 10, 10)

        reaper.ImGui_Text(ctx, tostring(current_time))

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

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosX(ctx, settings_width - 80)
        reaper.ImGui_SetCursorPosY(ctx, settings_height - 35)
        if not settings_one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "Apply##settings_apply", 70) then
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
            --gson.SaveJSON(settings_path, Settings)
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
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
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
