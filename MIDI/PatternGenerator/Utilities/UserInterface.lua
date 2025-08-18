--@noindex
--@description Pattern generator user interface
--@author gaspard
--@about All user interface used in gaspard_Pattern generator.lua script

local Gui = {}

-- Get all elements
local settings_window = require('Utilities/GUI_Elements/Gui_Settings')
local presets_window = require('Utilities/GUI_Elements/Gui_Presets')
local sample_window = require('Utilities/GUI_Elements/Gui_SampleZone')
local pattern_window = require('Utilities/GUI_Elements/Gui_PatternZone')
local piano_roll = require('Utilities/GUI_Elements/Gui_PianoRoll')

--#region Initial Variables
local og_window_width = 858
local og_window_height = 330
local og_win_min_w = og_window_width
local og_win_min_h = og_window_height
window_width = og_window_width
window_height = og_window_height
local topbar_height = 30
local small_font_size = style_font.size * 0.75
local window_name = 'PATTERN GENERATOR'
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local wait = 0
--#endregion

-- Get GUI style from file
local function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua'
    local style = dofile(gui_style_settings_path)
    style_font = style.font
    style_vars = style.vars
    style_colors = style.colors
end

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
    if reaper.ImGui_BeginChild(ctx, 'child_top_bar', window_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        local spacing = 5
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), spacing, 0)

        reaper.ImGui_SameLine(ctx)

        local button_w = System.separator == '\\' and 80 or 90
        local small_button_w = 18
        local presets_width = window_width > 369 and button_w or small_button_w
        local settings_width = window_width > 305 and button_w or small_button_w
        local quit_width = small_button_w
        local padding, _ = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())
        local buttons_width = presets_width + settings_width + quit_width + 3 * padding + 2 * spacing
        reaper.ImGui_SetCursorPos(ctx, window_width - buttons_width, 0)

        if reaper.ImGui_BeginChild(ctx, 'child_top_bar_buttons', buttons_width, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
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
local function VisualElements()
    local child_width = 600 - 16 - 8
    local child_height = 330 - topbar_height - 40
    if reaper.ImGui_BeginChild(ctx, 'child_sample_zone', child_width * 0.5, child_height, reaper.ImGui_ChildFlags_Border()) then
        sample_window.Show()
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_patterns_zone', child_width * 0.4, child_height, reaper.ImGui_ChildFlags_Border()) then
        pattern_window.Show()
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll', 308, child_height, reaper.ImGui_ChildFlags_Border()) then
        piano_roll.Show()
        reaper.ImGui_EndChild(ctx)
    end
end

local function VisualMidiExportSettings()
    reaper.ImGui_Text(ctx, 'MIDI EXPORT SETTINGS')
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextDisabled(ctx, 'Select these settings in the MIDI export window.')
    reaper.ImGui_Dummy(ctx, 1, 1)
    reaper.ImGui_Text(ctx, 'INPUT:')
    reaper.ImGui_RadioButton(ctx, 'Consolidate time: Time selection only', true)
    reaper.ImGui_RadioButton(ctx, 'Consolidate MIDI items: Selected items only', true)
    reaper.ImGui_Dummy(ctx, 1, 1)
    reaper.ImGui_Text(ctx, 'OUTPUT:')
    reaper.ImGui_RadioButton(ctx, 'Export to MIDI file: Multitrack MIDI file (type 1 MIDI file)', true)
    reaper.ImGui_Text(ctx, 'PPQN:')
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 50)
    reaper.ImGui_InputText(ctx, '##input_ppqn', '960', reaper.ImGui_InputTextFlags_ReadOnly())
    reaper.ImGui_Checkbox(ctx, 'Embed project tempo/time signature changes', true)
    reaper.ImGui_Checkbox(ctx, 'Embed SMPTE offset', true)
    reaper.ImGui_Checkbox(ctx, 'Export project markers as MIDI:', true)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, 'markers')
    reaper.ImGui_Checkbox(ctx, "Only export project markers that begin with '#'", false)
end

-- Gui Version on bottom right
local function VisualVersion()
    local text = 'gaspard v'..version
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

local function ExportMidiPattern(item)
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    local item_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local time_start, time_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange2(0, true, false, item_start, item_end, false)
    local retval, pattern_name = reaper.GetUserInputs('SAVE PATTERN', 1, 'Pattern name:', '')
    if retval then
        reaper.CF_SetClipboard(patterns_path..System.separator..pattern_name..'.mid')
        local text_part_1 = 'The midi patterns path has been set to clipboard. Paste pattern in next window to save.\nPattern name: '
        local text_part_2 = '\nSettings to select are displayed in main Pattern Generator window.'
        retval = reaper.MB(text_part_1..pattern_name..text_part_2, 'WARNING', 1)
        if retval == 1 then
            reaper.Main_OnCommand(40849, 0) -- Export MIDI
            System.ScanPatternFiles()
        end
    end
    reaper.GetSet_LoopTimeRange2(0, true, false, time_start, time_end, false)

    reaper.Undo_EndBlock('gaspard_Pattern generator_ExportMidiPattern', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

function Gui.Init()
    GetGuiStylesFromFile()
    WindowInit()
end

function Gui.Loop()
    System.ProjectUpdates()
    System.SamplesListUpdate()

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
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, og_win_min_w, og_win_min_h, math.huge, math.huge)

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

        -- Script GUI Elements and MIDI Export settings
        if System.show_midi_export_settings then
            local item = reaper.GetSelectedMediaItem(0, 0)
            if item then
                VisualMidiExportSettings()
                if wait > 0 then
                    System.show_midi_export_settings = false
                    reaper.defer(ExportMidiPattern(item))
                end
                wait = wait + 1
            else
                reaper.MB('No item selected.\nPlease select one midi item.', 'ERROR', 0)
                VisualElements()
                System.show_midi_export_settings = false
            end
        else
            if wait > 0 then wait = 0 end
            VisualElements()
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
