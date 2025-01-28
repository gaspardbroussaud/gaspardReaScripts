--@noindex
--@description Pattern generator user interface
--@author gaspard
--@about All user interface used in gaspard_Pattern generator.lua script

local Gui = {}

-- Get all elements
local settings_window = require('Utilities/GUI_Elements/Gui_Settings')
local presets_window = require('Utilities/GUI_Elements/Gui_Presets')
local drop_window = require('Utilities/GUI_Elements/Gui_DropZone')

--#region Initial Variables
local og_window_width = 500
local og_window_height = 300
window_width = og_window_width
window_height = og_window_height
local topbar_height = 30
local font_size = 16
local small_font_size = font_size * 0.75
local window_name = "PATTERN GENERATOR"
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
--#endregion

-- Get GUI style from file
local function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_vars = style.vars
    style_colors = style.colors
end

-- Init ImGui
local function WindowInit()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', font_size)
    small_font = reaper.ImGui_CreateFont('sans-serif', small_font_size, reaper.ImGui_FontFlags_Italic())
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, small_font)
end

-- GUI Top Bar
local function VisualTopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        local spacing = 5
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), spacing, 0)

        reaper.ImGui_SameLine(ctx)

        local button_w = 80
        local small_button_w = 18
        local presets_width = window_width > 369 and button_w or small_button_w
        local settings_width = window_width > 305 and button_w or small_button_w
        local quit_width = small_button_w
        local padding, _ = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
        local buttons_width = presets_width + settings_width + quit_width + 3 * padding + 2 * spacing
        reaper.ImGui_SetCursorPos(ctx, window_width - buttons_width, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", buttons_width, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            local text = presets_width == button_w and 'PRESETS' or 'P'
            if reaper.ImGui_Button(ctx, text..'##presets_button', presets_width) then
                show_presets = not show_presets
                if show_presets then System.ScanPresetFiles()
                else System.focus_main_window = false end
            end
            reaper.ImGui_SameLine(ctx)
            text = settings_width == button_w and 'SETTINGS' or 'S'
            if reaper.ImGui_Button(ctx, text..'##settings_button', settings_width) then
                show_settings = not show_settings
                if show_settings then settings_window.GetSettings()
                else System.focus_main_window = false end
            end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'X##quit_button', quit_width) then
                open = false
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
    end
end

-- Gui window elements
local function VisualElements(child_width, child_height)
    drop_window.Show()
end

-- Gui Version on bottom right
local function VisualVersion()
    local text = "gaspard v"..version
    reaper.ImGui_PushFont(ctx, small_font)
    local w, h = reaper.ImGui_CalcTextSize(ctx, text)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_PopFont(ctx)
end

-- Push all GUI style settings
local function ImGuiPushTheme()
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
local function ImGuiPopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

function Gui.Init()
    GetGuiStylesFromFile()
    WindowInit()
end

function Gui.Loop()
    ImGuiPushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()

    if System.focus_main_window then
        reaper.ImGui_SetNextWindowFocus(ctx)
        local hwnd = reaper.JS_Window_Find(window_name, true)
        if hwnd then reaper.JS_Window_SetFocus(hwnd) end
        System.focus_main_window = false
    end

    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, 244, 400, math.huge, math.huge)

    -- Font
    reaper.ImGui_PushFont(ctx, font)

    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)
    --current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        VisualTopBar()

        -- Presets window
        if show_presets then presets_window.Show() end

        -- Settings window
        if show_settings then settings_window.Show() end

        -- Script GUI Elements
        local child_width = window_width - 16
        local child_height = window_height - topbar_height - 40
        if reaper.ImGui_BeginChild(ctx, "child_global", child_width, child_height, reaper.ImGui_ChildFlags_Border()) then
            VisualElements(child_width, child_height)
            reaper.ImGui_EndChild(ctx)
        end

        -- Show script version on  bottom right
        VisualVersion()

        reaper.ImGui_End(ctx)
    end

    ImGuiPopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui.Loop)
    end
end

return Gui
