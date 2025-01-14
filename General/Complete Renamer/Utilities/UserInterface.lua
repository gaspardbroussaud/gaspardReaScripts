-- @noindex
-- @description Complete renamer user interface
-- @author gaspard
-- @about All user interface used in gaspard_Complete renamer.lua script

local Gui = {}

local rules_window = require('Utilities/GUI_Elements/Gui_Rules')
local userdata_window = require('Utilities/GUI_Elements/Gui_Userdata')

--#region Initial Variables
local og_window_width = 800
local og_window_height = 650
window_width = og_window_width
window_height = og_window_height
local topbar_height = 30
local settings_amount_height = 0.6
local font_size = 16
local small_font_size = font_size * 0.75
local window_name = "COMPLETE RENAMER"
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local top_height_ratio = 0.3
local is_resizing = false
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

-- Gui Settings
local function VisualSettings()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
    local settings_width = og_window_width - 350
    local settings_height = og_window_height * settings_amount_height
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        if reaper.ImGui_BeginChild(ctx, "child_settings_window", settings_width - 16, settings_height - 74, reaper.ImGui_ChildFlags_Border()) then
            local changed = false
            if changed then settings_one_changed = true end

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosX(ctx, settings_width - 80)
        reaper.ImGui_SetCursorPosY(ctx, settings_height - 35)
        if not settings_one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "Apply##settings_apply", 70) then
            --ApplySettings()
            --gson.SaveJSON(settings_path, Settings)
            settings_one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        if settings_one_changed then
            ResetUnappliedSettings()
            settings_one_changed = false
        end
        show_settings = false
    end
end

-- GUI Global Elements
local function VisualElements()
    local child_width = window_width - 16
    local child_height = window_height - topbar_height
    local splitter_size = 5

    local top_height = math.floor(child_height * top_height_ratio)
    local bottom_height = child_height - top_height - splitter_size - 40

    if reaper.ImGui_BeginChild(ctx, "child_top_ruleset", child_width, top_height, reaper.ImGui_ChildFlags_Border()) then
        --rules_popup.ShowVisuals()
        rules_window.Show()
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_SetCursorPosY(ctx, top_height + topbar_height + 11 + (splitter_size * 0.5))
    reaper.ImGui_Separator(ctx)

    reaper.ImGui_SetCursorPosX(ctx, 12)
    reaper.ImGui_SetCursorPosY(ctx, top_height + topbar_height + 10)
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

    reaper.ImGui_SetCursorPosY(ctx, top_height + topbar_height + 10 + splitter_size)
    if reaper.ImGui_BeginChild(ctx, "child_bottom_userdata", child_width, bottom_height, reaper.ImGui_ChildFlags_Border()) then
        userdata_window.ShowVisuals()
        reaper.ImGui_EndChild(ctx)
    end
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

-- At every frame
local function OnTick()
    System.ProjectUpdates()
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
        --System.ClearUserdataSelection()
        System.ClearTableSelection(ruleset)
    end
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
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())

    -- Font
    reaper.ImGui_PushFont(ctx, font)

    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)
    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        VisualTopBar()

        -- Settings window
        if show_settings then VisualSettings() end

        -- Script GUI Elements
        VisualElements()

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
