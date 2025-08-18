--@noindex
--@description Complete renamer user interface
--@author gaspard
--@about All user interface used in gaspard_Complete renamer.lua script

local Gui = {}

local rules_window = require('Utilities/GUI_Elements/Gui_Rules')
local userdata_window = require('Utilities/GUI_Elements/Gui_Userdata')
local presets_window = require('Utilities/GUI_Elements/GUI_Presets')
local settings_window = require('Utilities/GUI_Elements/Gui_Settings')

--#region Initial Variables
-- Get GUI style from file
local function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_font = style.font
    style_vars = style.vars
    style_colors = style.colors
end
GetGuiStylesFromFile()
local og_window_width = 800
local og_window_height = 650
window_width = og_window_width
window_height = og_window_height
local topbar_height = 30
local small_font_size = style_font.size * 0.75
local window_name = "COMPLETE RENAMER"
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local top_height_ratio = 0.3
local is_resizing = false
--#endregion

-- Init ImGui
local function WindowInit()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont(style_font.style)
    small_font = reaper.ImGui_CreateFont(style_font.style, reaper.ImGui_FontFlags_Italic())
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

-- GUI Global Elements
local function VisualElements(child_width, child_height)
    child_height = child_height - 35
    local splitter_size = 5

    local top_height = math.floor(child_height * top_height_ratio)
    local bottom_height = child_height - top_height - splitter_size

    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) - 8)
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 8)
    if reaper.ImGui_BeginChild(ctx, "child_top_ruleset", child_width, top_height, reaper.ImGui_ChildFlags_Border()) then
        rules_window.Show()
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_SetCursorPosY(ctx, top_height + (splitter_size * 0.5))
    reaper.ImGui_Separator(ctx)

    reaper.ImGui_SetCursorPosX(ctx, 12)
    reaper.ImGui_SetCursorPosY(ctx, top_height)
    reaper.ImGui_InvisibleButton(ctx, "button_splitter", child_width - 8, splitter_size)

    if reaper.ImGui_IsItemHovered(ctx) or is_resizing then
        reaper.ImGui_SetMouseCursor(ctx, reaper.ImGui_MouseCursor_ResizeNS())
    end
    if reaper.ImGui_IsItemActive(ctx) then
        is_resizing = true
        local _, mouse_delta_y = reaper.ImGui_GetMouseDelta(ctx)
        top_height_ratio = math.max(0.1, math.min(0.8, top_height_ratio + mouse_delta_y / child_height))
    elseif is_resizing then
        is_resizing = false
    end

    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) - 8)
    reaper.ImGui_SetCursorPosY(ctx, top_height + splitter_size)
    if reaper.ImGui_BeginChild(ctx, "child_bottom_userdata", child_width, bottom_height, reaper.ImGui_ChildFlags_Border()) then
        userdata_window.ShowVisuals()
        reaper.ImGui_EndChild(ctx)
    end

    local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    local button_x = 200
    if window_width < 245 then button_x = child_width - 17 end
    local disable = not System.one_renamed
    if disable then reaper.ImGui_BeginDisabled(ctx) end
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x)
    if reaper.ImGui_Button(ctx, "RENAME##apply_button", button_x) then
        System.ApplyReplacedNames()
        System.one_renamed = false
    end
    if disable then reaper.ImGui_EndDisabled(ctx) end
end

-- Gui Version on bottom right
local function VisualVersion()
    local text = "gaspard v"..version
    reaper.ImGui_PushFont(ctx, small_font, small_font_size)
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

-- At every frame
local function OnTick()
    System.ProjectUpdates()
    System.KeyboardHold()
end

function Gui.Init()
    GetGuiStylesFromFile()
    WindowInit()
end

function Gui.Loop()
    OnTick()

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
    reaper.ImGui_PushFont(ctx, font, style_font.size)

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
