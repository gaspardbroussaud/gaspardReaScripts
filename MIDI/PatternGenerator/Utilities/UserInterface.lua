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
topbar_height = 30
local font_size = 16
local small_font_size = font_size * 0.75
local icon_size = 22
local window_name = 'PATTERN GENERATOR'
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local wait = 0
--#endregion

-- Init ImGui
local function WindowInit()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    italic_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
    icon_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, italic_font)
    reaper.ImGui_Attach(ctx, icon_font)
end

-- GUI Top Bar (GaspaReaLauncher style)
local function VisualTopBar()
    reaper.ImGui_BeginGroup(ctx)
    -- Name and version
    reaper.ImGui_Text(ctx, window_name)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, italic_font, small_font_size)
    reaper.ImGui_Text(ctx, 'v' .. version)
    reaper.ImGui_PopFont(ctx)

    -- Icon buttons (right to left)
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false})
    table.insert(menu, {icon = 'GEAR', hint = 'Settings', font = icon_font, size = icon_size, right_click = false})
    table.insert(menu, {icon = 'BOOKMARK', hint = 'Presets', font = icon_font, size = icon_size, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
            if show_settings then settings_window.GetSettings()
            else System.focus_main_window = false end
        elseif button == 'BOOKMARK' then
            show_presets = not show_presets
            if show_presets then System.ScanPresetFiles()
            else System.focus_main_window = false end
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

-- Gui window elements
local function VisualElements()
    local child_width = 600 - 16 - 8
    local _, child_height = reaper.ImGui_GetContentRegionAvail(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_sample_zone', child_width * 0.5, child_height, reaper.ImGui_ChildFlags_Borders()) then
        sample_window.Show()
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_patterns_zone', child_width * 0.4, child_height, reaper.ImGui_ChildFlags_Borders()) then
        pattern_window.Show()
        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll', 308, child_height, reaper.ImGui_ChildFlags_Borders()) then
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

-- Push all GUI style settings
local function ImGuiPushTheme()
    for i = 1, #GUI_STYLE.VARS do
        reaper.ImGui_PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        reaper.ImGui_PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
local function ImGuiPopTheme()
    reaper.ImGui_PopStyleVar(ctx, #GUI_STYLE.VARS)
    reaper.ImGui_PopStyleColor(ctx, #GUI_STYLE.COLORS)
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
    reaper.ImGui_PushFont(ctx, font, font_size)

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

        reaper.ImGui_End(ctx)
    end

    ImGuiPopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui.Loop)
    end
end

return Gui
