--@noindex
--@description Pattern manipulator utility Display window
--@author gaspard
--@about Pattern manipulator utility

local gpmgui = {}

local window_samples = require('Utilities/gpm_DisplaySamples')
local window_tabs = require('Utilities/gpm_DisplayTab')

-- Window variables
og_window_width = 850
local og_window_height = 300
local min_width, min_height = 735, 250
local max_width, max_height = 1000, 400
window_width, window_height = og_window_width, og_window_height
window_x, window_y = 0, 0
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local window_name = "PATTERN MANIPULATOR"

-- Sizing variables
topbar_height = 30
font_size = 16
small_font_size = font_size * 0.75

-- ImGui Init
ctx = reaper.ImGui_CreateContext('random_play_context')
font = reaper.ImGui_CreateFont('sans-serif', font_size)
italic_font = reaper.ImGui_CreateFont('sans-serif', font_size, reaper.ImGui_FontFlags_Italic())
small_font = reaper.ImGui_CreateFont('sans-serif', small_font_size, reaper.ImGui_FontFlags_Italic())
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, italic_font)
reaper.ImGui_Attach(ctx, small_font)
global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

-- Get GUI style from file
local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
local style = dofile(gui_style_settings_path)
local style_vars = style.vars
local style_colors = style.colors

-- GUI Top Bar
local function TopBarDisplay()
    -- GUI Menu Bar
    local child_width = window_width - global_spacing
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", child_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Text(ctx, "x="..window_x.." ; y="..window_y.." / w="..window_width.." ; h="..window_height)

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

-- Gui Version on bottom right
local function VersionDisplay()
    reaper.ImGui_PushFont(ctx, small_font)
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)
end

-- Set all child elements area attribution
local function ElementsDisplay()
    local child_width = window_width - (global_spacing * 2)
    local child_height = window_height - topbar_height - small_font_size - 30
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + global_spacing)
    if reaper.ImGui_BeginChild(ctx, "child_tabs", child_width, child_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_SetCursorPosX(ctx, 0)
        reaper.ImGui_SetCursorPosY(ctx, 0)
        window_samples.Show()

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + global_spacing)
        reaper.ImGui_SetCursorPosY(ctx, 0)
        window_tabs.Show()

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

-- Main loop
function gpmgui.Loop()
    -- On tick
    gpmsys.sample_list = gpmsys_samples.CheckForSampleTracks()

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
        VersionDisplay()

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(gpmgui.Loop)
    end
end

return gpmgui
