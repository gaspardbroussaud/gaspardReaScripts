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
font_size = 16
local icon_size = 22
local og_window_width = 800
local og_window_height = 650
local min_width, min_height = 420, 400
window_width = og_window_width
window_height = og_window_height
window_x, window_y = 0, 0
topbar_height = 30
local window_name = "COMPLETE RENAMER"
local no_scrollbar_flags = ImGui.WindowFlags_NoScrollWithMouse | ImGui.WindowFlags_NoScrollbar
local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoTitleBar | no_scrollbar_flags
local top_height_ratio = 0.3
local is_resizing = false
local has_js_api = reaper.JS_Window_Find ~= nil and reaper.JS_Window_SetFocus ~= nil
--#endregion

-- Init ImGui (fonts from gaspard GUI_STYLE library)
local function WindowInit()
    ctx = ImGui.CreateContext('gaspard_complete_renamer')
    font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    small_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, ImGui.FontFlags_Italic)
    icon_font = ImGui.CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    ImGui.Attach(ctx, font)
    ImGui.Attach(ctx, small_font)
    ImGui.Attach(ctx, icon_font)
end

-- Position for floating panels (settings, presets): under the top bar, right aligned
function Gui_PanelPosition()
    return window_x + window_width - 8, window_y + topbar_height + 5
end

-- GUI Top Bar (GaspaReaLauncher style)
local function VisualTopBar()
    ImGui.BeginGroup(ctx)
    ImGui.Text(ctx, window_name)
    ImGui.SameLine(ctx)
    ImGui.PushFont(ctx, small_font, font_size * 0.75)
    ImGui.Text(ctx, "v" .. tostring(version))
    ImGui.PopFont(ctx)

    local menu = {
        {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false},
        {icon = 'GEAR', hint = 'Settings', font = icon_font, size = icon_size, right_click = false},
        {icon = 'BOOKMARK', hint = 'Presets', font = icon_font, size = icon_size, right_click = false},
        {icon = 'REFRESH_ARROW', hint = 'Refresh project data', font = icon_font, size = icon_size, right_click = false},
    }
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
            if show_settings then
                show_presets = false
                settings_window.GetSettings()
            else
                System.focus_main_window = true
            end
        elseif button == 'BOOKMARK' then
            show_presets = not show_presets
            if show_presets then
                show_settings = false
                System.ScanPresetFiles()
            else
                System.focus_main_window = true
            end
        elseif button == 'REFRESH_ARROW' then
            System.MarkDataDirty()
        end
    end
    ImGui.EndGroup(ctx)
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

-- Push all GUI style settings (gaspard GUI_STYLE library)
local function ImGuiPushTheme()
    for i = 1, #GUI_STYLE.VARS do
        ImGui.PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        ImGui.PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
local function ImGuiPopTheme()
    if #GUI_STYLE.VARS > 0 then ImGui.PopStyleVar(ctx, #GUI_STYLE.VARS) end
    if #GUI_STYLE.COLORS > 0 then ImGui.PopStyleColor(ctx, #GUI_STYLE.COLORS) end
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
    ImGui.SetNextWindowSizeConstraints(ctx, min_width, min_height, math.huge, math.huge)

    ImGui.PushFont(ctx, font, font_size)

    local visible
    visible, open = ImGui.Begin(ctx, window_name, true, window_flags)
    if visible then
        window_x, window_y = ImGui.GetWindowPos(ctx)
        window_width, window_height = ImGui.GetWindowSize(ctx)

        System.HandleShortcuts()

        -- Top bar elements
        VisualTopBar()

        -- Floating panels
        if show_presets then presets_window.Show() end
        if show_settings then settings_window.Show() end

        -- Script GUI Elements
        local child_width, child_height = ImGui.GetContentRegionAvail(ctx)
        if ImGui.BeginChild(ctx, "child_global", child_width, child_height, ImGui.ChildFlags_Borders) then
            VisualElements(child_width, child_height)
            ImGui.EndChild(ctx)
        end

        ImGui.End(ctx)
    end

    ImGui.PopFont(ctx)
    ImGuiPopTheme()

    if open then
        reaper.defer(Gui.Loop)
    end
end

return Gui
