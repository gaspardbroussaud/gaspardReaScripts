--@noindex
--@description Pattern Manipulator
--@author gaspard
--@version 0.0.1b
--@changelog
--  Initial commit
--@about
--  # Gaspard Reaper Launcher
--  Reaper Launcher for projects.

-- Toggle button state in Reaper
local action_name = ""
local version = "0.0"
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.3.2') -- current version at the time of writing the script

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
local gson = require('json_utilities_lib')
local script_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
local settings_path = script_path..'Utilities/gaspard_'..action_name..'_settings.json'
--------------------------------------------------------------------

-- GUI ELEMENTS ----------------------------------------------------

local project_list = {}
local function PopulateProjects()
    table.insert(project_list, {name = "my_first_project", selected = false, path = "path"})
    table.insert(project_list, {name = "big_file_for_project", selected = false, path = "path_number_2"})
end
PopulateProjects()
--------------------------------------------------------------------

-- GUI ELEMENTS ----------------------------------------------------

--#region GUI Variables
-- Window variables
local og_window_width = 850
local og_window_height = 300
local min_width, min_height = 500, 201
local max_width, max_height = 1000, 400
local window_width, window_height = og_window_width, og_window_height
local window_x, window_y = 0, 0
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local window_name = "GASPARD REA LAUNCHER"

-- Sizing variables
local topbar_height = 30
local font_size = 16
local small_font_size = font_size * 0.75

-- ImGui Init
local ctx = reaper.ImGui_CreateContext('random_play_context')
local font = reaper.ImGui_CreateFont('sans-serif', font_size)
local italic_font = reaper.ImGui_CreateFont('sans-serif', font_size, reaper.ImGui_FontFlags_Italic())
local small_font = reaper.ImGui_CreateFont('sans-serif', small_font_size, reaper.ImGui_FontFlags_Italic())
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, italic_font)
reaper.ImGui_Attach(ctx, small_font)
local global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

-- Get GUI style from file
local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
local style = dofile(gui_style_settings_path)
local style_vars = style.vars
local style_colors = style.colors
--#endregion

-- GUI Top Bar
local function TopBarDisplay()
    -- GUI Menu Bar
    local child_width = window_width - global_spacing
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", child_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Dummy(ctx, 3, 1)
        reaper.ImGui_SameLine(ctx)

        local spacing_x_2 = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing()) * 2
        local quit_w = 10 + spacing_x_2
        local y_pos = 0
        reaper.ImGui_SetCursorPos(ctx, child_width - quit_w - spacing_x_2, y_pos)
        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, 'X##quit_button', quit_w) then
            open = false
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
    end
end

-- Push all GUI style settings
local function Gui_PushTheme()
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
local function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

-- All GUI elements
local function ElementsDisplay()
    if reaper.ImGui_BeginListBox(ctx, "##project_listbox") then
        for i, project in ipairs(project_list) do
            changed, project.selected = reaper.ImGui_Selectable(ctx, project.name, project.selected)
        end

        reaper.ImGui_EndListBox(ctx)
    end

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_Button(ctx, "Add to favorites")
end

-- Main loop
local function Gui_Loop()
    -- On tick

    -- GUI --------
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, max_width, max_height)
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

    if visible then
        TopBarDisplay()

        ElementsDisplay()

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui_Loop)
    end
end

Gui_Loop()
