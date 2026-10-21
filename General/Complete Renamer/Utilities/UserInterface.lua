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
local DEFAULT_STYLE = {font = {style = "sans-serif", size = 14}, vars = {}, colors = {}}

-- Get GUI style from file (falls back to default style if file is missing)
local function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local ok, style = pcall(dofile, gui_style_settings_path)
    if not ok or type(style) ~= "table" then style = DEFAULT_STYLE end
    style_font = style.font or DEFAULT_STYLE.font
    style_vars = style.vars or {}
    style_colors = style.colors or {}
end
GetGuiStylesFromFile()

local og_window_width = 800
local og_window_height = 650
window_width = og_window_width
window_height = og_window_height
window_x, window_y = 0, 0
local topbar_height = 30
local small_font_size = style_font.size * 0.75
local window_name = "COMPLETE RENAMER"
local no_scrollbar_flags = ImGui.WindowFlags_NoScrollWithMouse | ImGui.WindowFlags_NoScrollbar
local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoTitleBar | no_scrollbar_flags
local top_height_ratio = 0.3
local is_resizing = false
local has_js_api = reaper.JS_Window_Find ~= nil and reaper.JS_Window_SetFocus ~= nil
--#endregion

-- Init ImGui
local function WindowInit()
    ctx = ImGui.CreateContext('gaspard_complete_renamer')
    font = ImGui.CreateFont(style_font.style)
    small_font = ImGui.CreateFont(style_font.style, ImGui.FontFlags_Italic)
    ImGui.Attach(ctx, font)
    ImGui.Attach(ctx, small_font)
end

-- GUI Top Bar
local function VisualTopBar()
    if ImGui.BeginChild(ctx, "child_top_bar", window_width, topbar_height, ImGui.ChildFlags_None, no_scrollbar_flags) then
        ImGui.Text(ctx, window_name)

        local spacing = 5
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, spacing, 0)
        ImGui.SameLine(ctx)

        local button_w = 95
        local small_button_w = 18
        local presets_width = window_width > 369 and button_w or small_button_w
        local settings_width = window_width > 305 and button_w or small_button_w
        local quit_width = small_button_w
        local padding = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local buttons_width = presets_width + settings_width + quit_width + 3 * padding + 2 * spacing
        ImGui.SetCursorPos(ctx, window_width - buttons_width, 0)

        if ImGui.BeginChild(ctx, "child_top_bar_buttons", buttons_width, topbar_height, ImGui.ChildFlags_None, no_scrollbar_flags) then
            ImGui.Dummy(ctx, 3, 1)
            ImGui.SameLine(ctx)
            local text = presets_width == button_w and 'PRESETS' or 'P'
            if ImGui.Button(ctx, text .. '##presets_button', presets_width) then
                show_presets = not show_presets
                if show_presets then System.ScanPresetFiles()
                else System.focus_main_window = false end
            end
            ImGui.SameLine(ctx)
            text = settings_width == button_w and 'SETTINGS' or 'S'
            if ImGui.Button(ctx, text .. '##settings_button', settings_width) then
                show_settings = not show_settings
                if show_settings then settings_window.GetSettings()
                else System.focus_main_window = false end
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, 'X##quit_button', quit_width) then
                open = false
            end
            ImGui.EndChild(ctx)
        end

        ImGui.PopStyleVar(ctx, 1)
        ImGui.EndChild(ctx)
    end
end

-- GUI Global Elements
local function VisualElements(child_width, child_height)
    child_height = child_height - 35
    local splitter_size = 5

    local top_height = math.floor(child_height * top_height_ratio)
    local bottom_height = child_height - top_height - splitter_size

    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) - 8)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) - 8)
    if ImGui.BeginChild(ctx, "child_top_ruleset", child_width, top_height, ImGui.ChildFlags_Borders) then
        rules_window.Show()
        ImGui.EndChild(ctx)
    end

    ImGui.SetCursorPosY(ctx, top_height + (splitter_size * 0.5))
    ImGui.Separator(ctx)

    ImGui.SetCursorPosX(ctx, 12)
    ImGui.SetCursorPosY(ctx, top_height)
    ImGui.InvisibleButton(ctx, "button_splitter", child_width - 8, splitter_size)

    if ImGui.IsItemHovered(ctx) or is_resizing then
        ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNS)
    end
    if ImGui.IsItemActive(ctx) then
        is_resizing = true
        local _, mouse_delta_y = ImGui.GetMouseDelta(ctx)
        top_height_ratio = math.max(0.1, math.min(0.8, top_height_ratio + mouse_delta_y / child_height))
    elseif is_resizing then
        is_resizing = false
    end

    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) - 8)
    ImGui.SetCursorPosY(ctx, top_height + splitter_size)
    if ImGui.BeginChild(ctx, "child_bottom_userdata", child_width, bottom_height, ImGui.ChildFlags_Borders) then
        userdata_window.ShowVisuals()
        ImGui.EndChild(ctx)
    end

    local x = ImGui.GetContentRegionAvail(ctx)
    local button_x = 200
    if window_width < 245 then button_x = child_width - 17 end
    local disable = not System.one_renamed
    if disable then ImGui.BeginDisabled(ctx) end
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + x - button_x)
    if ImGui.Button(ctx, "RENAME##apply_button", button_x) then
        System.ApplyReplacedNames()
    end
    if disable then ImGui.EndDisabled(ctx) end
end

-- Gui Version on bottom right
local function VisualVersion()
    local text = "gaspard v" .. tostring(version)
    ImGui.PushFont(ctx, small_font, small_font_size)
    local w, h = ImGui.CalcTextSize(ctx, text)
    ImGui.SetCursorPosX(ctx, window_width - w - 10)
    ImGui.SetCursorPosY(ctx, window_height - h - 10)
    ImGui.Text(ctx, text)
    ImGui.PopFont(ctx)
end

-- Push all GUI style settings
local function ImGuiPushTheme()
    for i = 1, #style_vars do
        ImGui.PushStyleVar(ctx, style_vars[i].var, style_vars[i].value, style_vars[i].value2)
    end
    for i = 1, #style_colors do
        ImGui.PushStyleColor(ctx, style_colors[i].col, style_colors[i].value)
    end
end

-- Pop all GUI style settings
local function ImGuiPopTheme()
    if #style_vars > 0 then ImGui.PopStyleVar(ctx, #style_vars) end
    if #style_colors > 0 then ImGui.PopStyleColor(ctx, #style_colors) end
end

function Gui.Init()
    WindowInit()
end

function Gui.Loop()
    System.Update()

    ImGuiPushTheme()

    if System.focus_main_window then
        ImGui.SetNextWindowFocus(ctx)
        if has_js_api then
            local hwnd = reaper.JS_Window_Find(window_name, true)
            if hwnd then reaper.JS_Window_SetFocus(hwnd) end
        end
        System.focus_main_window = false
    end

    ImGui.SetNextWindowSize(ctx, window_width, window_height, ImGui.Cond_Once)
    ImGui.SetNextWindowSizeConstraints(ctx, 244, 400, math.huge, math.huge)

    ImGui.PushFont(ctx, font, style_font.size)

    local visible
    visible, open = ImGui.Begin(ctx, window_name, true, window_flags)
    if visible then
        window_x, window_y = ImGui.GetWindowPos(ctx)
        window_width, window_height = ImGui.GetWindowSize(ctx)

        System.HandleShortcuts()

        -- Top bar elements
        VisualTopBar()

        -- Presets window
        if show_presets then presets_window.Show() end

        -- Settings window
        if show_settings then settings_window.Show() end

        -- Script GUI Elements
        local child_width = window_width - 16
        local child_height = window_height - topbar_height - 40
        if ImGui.BeginChild(ctx, "child_global", child_width, child_height, ImGui.ChildFlags_Borders) then
            VisualElements(child_width, child_height)
            ImGui.EndChild(ctx)
        end

        -- Show script version on bottom right
        VisualVersion()

        ImGui.End(ctx)
    end

    ImGui.PopFont(ctx)
    ImGuiPopTheme()

    if open then
        reaper.defer(Gui.Loop)
    end
end

return Gui
